# PR——<task-name>

> 目标项目的PR准备记录。代码审计通过、用户门禁2确认后备好；上游社区草稿另落`upstream/`（retro阶段），经用户最终确认后提交。
> 清单条目不适用时写"不适用＋一行理由"，不删条。

## 1. 提交计划

改动涉及的仓库各自划分commit，一个commit单一主题：

| 仓 | 序 | 提交信息 | 涉及文件 |
|---|---|---|---|
| velox | 1 | | |
| velox4j | 1 | | |
| gluten | 1 | | |

## 2. PR描述

- 标题：<一行概括>
- 背景与动机：<引DESIGN.md§1>
- 改动摘要：<引IMPLEMENTATION.md§1>
- 验证结果：<引TEST_REPORT.md§6与`e2e/verify/RESULTS.md`路径>

## 3. 合入前检查单

- [ ] CODE_AUDIT.md裁决通过
- [ ] 用户门禁2已确认
- [ ] IMPLEMENTATION.md与最终代码一致（返工后已原地刷新）
- [ ] 单测全过
- [ ] 轻量e2e自测通过（作业到FINISHED）
- [ ] 未自动提交任何issue或PR
