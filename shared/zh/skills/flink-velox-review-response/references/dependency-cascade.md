# 三仓依赖级联（velox / velox4j / gluten）

review-response skill 的参考手册：链上任一仓前进时，ref / hash / 仓 URL 如何级联。以下规则经多轮三仓检视链实战验证。

## 链条

```
velox (bigo-sg)  ──velox-ref.txt──▶  velox4j (bigo-sg)  ──CI pin──▶  gluten (apache)
```

velox4j 以固定 velox commit 构建：`src/main/cpp/velox-ref.txt`（commit SHA）+ `velox-ref-hash.txt`（该 commit 的 codeload zip MD5），两个文件必须一起改。gluten 不直接 pin velox；其 CI（`flink.yml`）clone 一个 velox4j 分支的指定 commit，从那里构建整栈。

## 触发矩阵

| 事件 | velox4j 动作 | gluten 动作 |
|---|---|---|
| velox 分支新增 commit（PR 未合并） | velox-ref.txt/hash 更新为 fork 分支新头 | CI pin 更新为 velox4j 新 commit |
| velox PR 合并上游 | ref 指上游合并头；仓 URL 从 fork 切回上游；从上游 codeload 重算 hash | 等待——不做 pin 跳变（见时机规则） |
| velox4j PR 合并上游 | — | clone 行切 bigo-sg 分支 + pin 指合并头 |

## 中间态时机规则

velox4j 的 pin PR 还在检视中时，其头 commit 会持续移动。**不要**为每个 velox4j commit 更新 gluten 引用——等 velox4j 合并后一次性切到上游终态。这避免 pin 链反复跳变（实测教训：中间 pin 更新往往几天内就被合并取代）。

## md5 计算约束

`velox-ref-hash.txt` 是 `https://github.com/<org>/velox/archive/<完整SHA>.zip` 的 MD5。codeload zip 只对**已 push** 的 commit 存在，因此操作顺序固定：先 push velox、算 hash、再更新 velox4j。示例（合并后切回上游）：

```bash
M=$(git -C repos/velox rev-parse <上游合并头>)
MD5=$(curl -sL "https://github.com/bigo-sg/velox/archive/${M}.zip" -o /tmp/v.zip \
      && md5sum /tmp/v.zip | awk '{print $1}')
cd repos/velox4j   # 在 pin 分支上
echo "$M"   > src/main/cpp/velox-ref.txt
echo "$MD5" > src/main/cpp/velox-ref-hash.txt
git add -u && git commit -m "Point the velox ref at the merged upstream revision"
```

## 合并后 URL 回归上游

功能 PR 在途时，velox4j 的 CMakeLists 指向个人 fork（`VELOX_REPO` 与 `VELOX_SOURCE_URL` 两行为 fork 的 `<owner>/velox`）。velox PR 合并后两行都切回上游仓——fork 中转不再需要：

```bash
sed -i 's/<fork-owner>\/velox/bigo-sg\/velox/' src/main/cpp/CMakeLists.txt   # 两行
```

gluten 的 CI 路由同构：`.github/workflows/flink.yml` 与 `gluten-flink/docs/Flink.md` 中，clone 行从 fork 的 pin 分支切到 `-b gluten-20260829 https://github.com/bigo-sg/velox4j.git`，`git reset --hard <sha>` 目标切到 velox4j 合并头。

## 本地格式工具链（velox 仓）

`make format-fix CHECK_BASE=gluten-20260829` 的工具链（pip 安装，与 CI 的 Ubuntu 24.04 apt 版本一致）：regex、black、pyyaml、cmakelang==0.6.13、clang-format 18。文件带 unstaged 修改时 check.py 拒绝执行——先 `git add` 再跑 `format-fix`。

## 跨分支受影响检查

任一仓合并后，检查其它在途分支是否与前进后的上游分叉。受影响分支用 **merge 而非 rebase** 同步——merge 保留原 commit 历史与检视锚点（锚点保护规则见 SKILL.md 阶段 4）。
