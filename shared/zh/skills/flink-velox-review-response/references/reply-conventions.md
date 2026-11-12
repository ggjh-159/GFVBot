# 回复惯例（review-response 模板）

对 reviewer 的回复遵循固定骨架——先感谢，再逐条对应并引用 commit。生成的草稿落 `tasks/<task-name>/upstream/review-response/replies/`，经逐条人工确认后才发布（见 SKILL.md 的「人为确认门」——任何对外内容未确认不发布）。回复一律英文；中文分析注记不强制位置。

## 每条回复的骨架

```
@<reviewer> Thanks for the review! <一句话概括处理结果>

- **<意见 1>**: <做了什么> — pushed in <sha8>.
- **<意见 2>**: <做了什么> — pushed in <sha8>.
- **<未采纳的 suggestion>**: noted, <原因>.
```

## must-fix

回应 reviewer 描述的确切缺陷、复述其措辞、点出钉住该修复的测试：

```
- **<被点名的问题>**: fixed in <sha8> — <改动一句话>. Verified by <新增/更新的测试名>.
```

## decision-needed（语义分歧）

agent 绝不选边——回复呈现用户的裁决及其依据：

```
- **<分歧点>**: we keep <选定方案> as an intentional deviation. <一句依据>.
  Documented at <代码位置> and pinned by <测试名>.
```

## evidence-first（reviewer 要求确认行为）

先做实验再起草。回复以结论开头，随后证据链（展示机制的源码锚点 file:line → 实证产物如 EXPLAIN 物理计划保留调用未折叠并附实际输出 → 补充细节如两种运行期求值粒度及本场景适用哪种），末句收束对本 PR 的含义——无需改动 / 已在 `<sha8>` 改动。

## wording / 仅注释

```
- **<措辞问题>**: reworded in <sha8>; comment-only change, no code change.
```

## claim 与实现不符（testing 段声明）

两种合法解——择一，绝不留不符声明悬空：代码补齐（首选，回复同时引用修复与测试）或删声明（回复声明已从描述移除——本 PR 不提供该支持）。

## 行级评论的回复位置

默认在 review 的会话线程给一条汇总回复（覆盖全部意见）；需要代码上下文才可读的观点，另在该行级评论处单独回复。分支历史移动过（merge 式同步）时附新旧 commit 映射，reviewer 才能找到锚定内容。

## PR 描述更新

载体：API `PATCH /repos/{owner}/{repo}/pulls/{n}`（body 整体替换）或网页手改——与评论发布同一确认门。patch 前先取现描述、生成新版、diff 展示确认。随附评论注明 "PR description updated accordingly"。描述大改时在 `descriptions/` 下留 `<repo>-pr<N>-description.old.md` 快照，追溯 claim 演进。
