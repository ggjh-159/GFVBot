---
name: flink-velox-review-response
description: 管理 velox / velox4j / gluten 三仓的上游交互全生命周期——issue 先行的提交准备、多轮检视意见的分诊与修复循环、合并后级联——所有对外动作均有逐条人工确认门。
---

# flink-velox-review-response

三个阶段覆盖一组修改的上游全程：Phase A 提交准备（issue 先行 + PR 链）、Phase B 检视意见循环（拉取 → 分诊 → 修复 → 推送 → 回复 → 描述同步）、Phase C 合并后级联。

## 适用时机

- plugin 的 retro 阶段产出上游草稿、PR 已提交并进入检视之后。
- 临时触发：velox / velox4j / gluten 任一开放 PR 上来了新检视意见（用户说"PR #N 有新意见"）。

## 纪律

1. **对外内容不确认不发布**：检视回复 / PR 描述 / issue 评论须全文逐条展示、逐条确认后发布（默认用户手动贴；agent 代发仅在明确授权下）；push 前确认 commit 摘要 + diff stat。详见"人为确认门"。
2. **已 review 的 commit 只追加不重写**：规则见阶段 4。
3. **PR 标题前缀**：用 `[FLINK][VL]` 或 `[GLUTEN-<id>][FLINK][VL]`——裸 `[FLINK]` 会触发 prestodb-ci 的 "Invalid link" 误报。
4. **PR 描述净化与依赖披露**：所有仓的 PR 描述不体现个人 fork 仓名与 GFV 相关名称；多仓改动必须写明 companion PR 链接、预期的 commit 配对、落仓顺序——缺失依赖说明是 reviewer 的标准扣分项。
5. **级联顺序**：velox → velox4j → gluten；ref / hash / URL 三要素一起改，改完跑构建确认。codeload hash 只对已 push 的 commit 存在，先 push velox 再更新 pin（细节见 `references/dependency-cascade.md`）。
6. **语义分歧交用户决策**：agent 绝不自行拍板；实证类意见先实验后回复。
7. **claim 与实现必须一致**：描述、回复、代码三者同步落笔；后续修改导致描述失实时必须同步更新描述（阶段 6 已含，此处为纪律重申）。
8. **CI 失败先归因**：仓内已知的系统性失败不属本 PR，引用仓内既有说明评论即可；归因本 PR 的才回修。推送是硬门禁：编译、format、新增/修改的 UT 全部本地通过才推；修改一仓时须确认对其它两仓测试无影响。
9. **过程记录**：每轮的产物留在 `tasks/<task-name>/upstream/review-response/` 的三类目录（archive / replies / descriptions）——过程记录与下一轮增量的基准，不与 retro 的 issue/PR 草稿混放。

## Phase A —— 提交准备

### issue 先行

一组修改（无论涉及几个仓）只提一个 issue，提在该组的入口仓：含 gluten 改动提 gluten；只涉及 velox / velox4j 的改动提 velox；单仓改动提本仓。入口仓的 PR 用 `Fixes #<id>` 关闭关联，其余仓的 PR 以 `issue: <仓>#<id>` 参考链接。

### PR 链顺序

按依赖序提交：velox（flinksql 实现是根产物）→ velox4j（pin 指向该 velox 头）→ gluten（CI 路由指向该 pin）。提交前对照纪律 3/4/5 核查标题、描述与 pin 输入。PR 由用户手动提交（框架原则：agent 绝不自动提交）；每仓提交后 skill 验证 PR 可达，并确认下一仓的 pin 输入已就绪。

## Phase B —— 检视意见循环

### 阶段 0 —— 访问与环境就绪

- **凭证分级**：查询端点匿名可用（60 次/时，单轮足够）；CI 日志下载与高频轮询需 PAT（公开仓 `public_repo` scope）。检测：`GITHUB_TOKEN` / `git credential fill` / `~/.netrc`。
- **不满足则指导闭环，直到通过**：申请（Settings → Developer settings → Personal access tokens → classic）→ 三选一配置（`export GITHUB_TOKEN` / `git config --global credential.helper store` / 写入 `~/.netrc`，curl 需 `--netrc-optional`，git 不走 netrc）→ 复查 `curl -s --netrc-optional https://api.github.com/user | grep '"login"'`（401 = token 未传到或失效；403 = 限速）。
- **环境就绪**：工作区经 `.gfvbot/env.json`（非必须）或根下 `repos/{velox,velox4j,gluten}` 布局定位；三仓 clone 与 remote 正确；JAVA_HOME / maven / cmake 可用；容器内 taskset 用合法核范围；velox4j 无 cpp 构建树时走 `mvn install -Dexec.skip=true`。

### 阶段 1 —— 拉取与存档

`bin/pull-reviews.sh <owner/repo> <pr> [输出文件]` 拉取三个端点（reviews、行级评论、会话评论），写入 `tasks/<task-name>/upstream/review-response/archive/<repo>-pr<N>-review-archive.md`。存档**按 review 分组**（状态 + body + 该 review 的行级评论，带 `文件:行号` 锚点）；独立行级评论与会话评论按时间排在其后。增量 = 与已有存档 diff，只呈现新 review / 新评论。

### 阶段 2 —— 分诊

逐条分类新意见：

- **must-fix**：代码缺陷——修复、验证、推送。
- **decision-needed**：语义分歧——整理选项与依据交用户决策，无论哪种走向都要有测试覆盖。
- **evidence-first**：先做实验（源码定位、EXPLAIN、实跑），再以证据链回答。
- **wording**：仅注释/措辞修复。
- **suggestion / minor**：不必然免改代码——逐条判断，采纳合理则照常修复推送；确认不动代码则在回复中说明理由。

### 阶段 3 —— 修复

切分支前：以语义名 stash 无关 WIP，切回后 pop（多任务并行先列 stash 清单再定位）。验证按语义影响面分级：

- **L1 编译 + format（永远必做，硬门禁）**：各仓编译必须通过 + format 必须过。velox `make format-fix CHECK_BASE=gluten-20260829`（pip 工具链与 check.py 的 staged 要求见 `references/dependency-cascade.md`）；velox4j `mvn spotless:apply` + `mvn test-compile -Dexec.skip=true`；gluten `mvn spotless:apply -pl planner,ut` + planner install。注意：编译验证要用不可欺骗的信号——`.class` 产物存在或单类实跑，不用"grep 无错误输出"（可被管道吞错/增量编译残留欺骗，实测教训：推送态曾携编译错误通过此类假绿）。
- **L2 单元测试（硬门禁，必须本地跑过才推送）**：新增/修改的测试必须通过；本仓受影响套件全量回归通过；修改 velox 时 velox4j/gluten 的 UT 也须跑一遍（跨仓影响是检视扣分项）。velox flinksql gtest；velox4j invocation 测试（需 .so，无则先构建，构建确实不可行时才退化为编译级 + CI 兜底并在回复中显式声明未本地验证）；gluten 纯 Java UT + 内嵌 SQL 测试。脚本化文本替换后必须验证生效（grep 确认旧模式消失），str.replace 静默失败是实测教训。
- **L3 e2e dual-run（仅运行时语义变化必做）**：按 flink-velox-e2e-verify skill 执行（部署新 jar + 双集群 + changelog 精确比较）；纯格式/测试/措辞改动跳过。**集群用完即停**（`stop-cluster.sh` + 杀残留 TM），容器内存有限，长跑任务验证完及时释放。

### 阶段 4 —— 提交与推送

核心：**已 review 的 commit 只追加不重写**——行级评论锚定在 commit SHA + (path, line) 上，SHA 一变锚点即断（outdated）。四条规则：

- 已 review 分支上的新内容 = 追加 commit；上游基线前进时用 **merge** 同步（干净的空 diff merge commit）。
- rebase / amend 仅限**未 push 的本地 commit**（如检视修复 commit 本身）；amend 前确认目标不是 merge commit。
- 维护者明确要求 rebase 时遵从——权威优先于锚点。
- **push 前先 sync fork**：`git fetch upstream && git merge upstream/<base>`（或 GitHub 页面 Sync fork），fork 落后上游会直接把冲突引进 PR。

push 被拒（non-fast-forward）时按上述规则判断是否允许 force-with-lease。**推送后跟踪 CI**：查 `commits/{sha}/check-runs`；失败先按纪律 8 归因；归因本 PR 的回到阶段 3 修复。

### 阶段 5 —— 回复

开头 @ 检视者 + 感谢 + 分条对应 + commit 引用；各分诊类的模板见 `references/reply-conventions.md`。默认组织为一条总评回复；长意见或依赖上下文的观点另在对应行级评论处单独回复。历史移动过（merge 式同步）时附新旧 commit 映射。

### 阶段 6 —— PR 描述同步

对照实现检查描述：tested 段用例数、claim 清单、纪律 4 的依赖披露是否仍然准确（companion PR 合并后要更新配对信息）。claim 与实现不符必须二选一——补实现（首选）或删声明，不符的 claim 不允许存留。描述经 `PATCH /repos/{owner}/{repo}/pulls/{n}`（body 整体替换，先取现描述、生成新版、展示 diff）或网页修改；随附评论注明 "PR description updated accordingly"。大改时在 `descriptions/` 下以 `.old.md` 后缀留旧版快照。

## Phase C —— 合并后级联

- **合并确认**：PR state 转 merged；`Fixes #` 的 issue 是否自动关闭。
- **级联动作**（见 `references/dependency-cascade.md`）：velox4j ref 指上游合并头、仓 URL 从 fork 切回上游、hash 从上游 codeload 重算；gluten 的 clone 行切上游分支、pin 指合并头。
- **跨分支受影响检查**：任一仓合并后，检查其它在途分支是否与前进后的上游分叉；受影响分支用 **merge** 同步（保护各自锚点）。
- **收尾**：archive/ 存档标记闭环；fork 分支保留。

## 人为确认门

| 动作 | 风险 | 门 |
|---|---|---|
| 拉取 / 存档 / 分析（只读） | 无 | 自由执行 |
| `git push` | 通知 reviewer、进 PR 历史 | 推前确认 commit 摘要 + diff stat |
| 检视回复 / PR 描述 / issue 评论 | 对外内容，代表作者立场 | **全文逐条展示、逐条确认后才发布**；默认用户手动贴，agent 代发（API）仅在明确授权下 |

产物按三类目录归位：回复草稿 `replies/<repo>-pr<N>-reply.md`（每轮刷新）、描述修改稿 `descriptions/<repo>-pr<N>-description.md`（旧版以 `.old.md` 同名留存）——两者都走门，不确认不发布。
