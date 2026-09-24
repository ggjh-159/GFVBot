# DESIGN——<task-name>

> 按节填写；标注"无"的节保留标题。本方案通过设计审计（通过/不通过）后方可进入实现。

## 1. 任务与输入

| 项 | 内容 |
|---|---|
| 目标函数 | `<FUNCTION(args)>` |
| SPEC | `tmp/<task-name>/architect/SPEC.md` |
| 语义基准 | `docs/gfvbot/shared/flink-expressions/<类别>/<FUNCTION>.md` |

## 2. velox现状调研

先查语义基准文档卡的"velox实现"一节，再到velox源码核实：

| 项 | 结论 | 证据（文件路径） |
|---|---|---|
| 文档卡标注 | <已有内建/sparksql套件/GFV自有/暂无> | 文档卡原文 |
| 源码核实 | <注册名与实现文件> | `velox/functions/...` |
| 可否复用 | <可直接复用/语义一致但须迁移至flinksql/语义不一致须重写/无实现> | 见第3节 |

**铁律**：无论调研结论如何，运行时路径一律在flinksql命名空间下注册（`velox/functions/flinksql/`），不得复用spark/presto注册。spark/presto实现仅作语义与写法参照。

## 3. 语义对照

逐项对照Flink语义与velox既有实现（若有），任何一项不一致即不能直接复用：

| 维度 | Flink语义 | velox既有实现语义 | 一致？ |
|---|---|---|---|
| NULL处理 | | | |
| 空串/空集合 | | | |
| 越界/非法参数 | | | |
| 类型矩阵 | | | |
| 返回类型与精度 | | | |
| 大小写/匹配方式等函数特有维度 | | | |

## 4. flinksql注册设计

| 项 | 设计 |
|---|---|
| 注册名 | `flinksql前缀下的<name>` |
| 实现文件 | `velox/functions/flinksql/<File>.h/.cpp` |
| 注册方式 | <registerFunction简单UDF/registerStatefulVectorFunction> |
| 签名清单 | <类型组合逐条列出> |
| CMake | `velox/functions/flinksql/CMakeLists.txt`新增条目 |
| 参考写法 | `velox/functions/flinksql/RegexFunctions.h`（既有in-tree参照） |

## 5. gluten映射设计

| 项 | 设计 |
|---|---|
| 映射位置 | `RexCallConverterFactory`的`<FUNCTION>`条目 |
| converter | <直接名映射/自研converter（说明修正逻辑）> |
| 无映射时行为 | 表达式转换失败、查询报错（GFV无回退）——确认本设计消除该失败 |

## 6. 实现计划

| 层 | 改动 | 文件 |
|---|---|---|
| velox | <函数实现+注册+CMake> | |
| gluten | <映射条目/converter> | |

## 7. 单元测试覆盖矩阵

| 用例 | 输入 | 期望 | 覆盖意图 |
|---|---|---|---|
| 基本功能 | | | |
| 各支持类型 | | | |
| NULL各参数位 | | | |
| 边界（空/越界/极值） | | | |
| 特殊场景（见第9节） | | | |

## 8. e2e测试覆盖矩阵

每条用例对应一个SQL文件（`e2e/sql/NNN_<intent>.sql`+固定输入数据），全部双端运行：

| 用例 | SQL意图 | 输入构造 | changelog形态 |
|---|---|---|---|
| 基本投影 | | | 追加流（仅+I） |
| NULL行 | | | |
| 边界值 | | | |
| 与其他表达式组合/嵌套 | | | |
| 有界聚合上下文 | | | 回撤流（-U/+U） |

## 9. 特殊场景

<逐条列出本函数特有的坑：如SPLIT_INDEX的0基vs1基下标、REGEXP的全串vs部分匹配、DECIMAL精度……每条给出预期行为与用例编号的对应关系>

## 10. 风险

| 风险 | 影响 | 缓解 |
|---|---|---|
| | | |
