# IMPLEMENTATION——<task-name>

> 实现记录。每次返工后原地刷新；交付前单测全过且代码评审通过。
> 清单条目不适用时写"不适用＋一行理由"，不删条。

## 1. 改动清单

逐文件列出，与`DESIGN.md`§4一一对应：

| 仓 | 文件 | 改动 | 对应设计条目 |
|---|---|---|---|
| velox | `velox/experimental/stateful/StatefulPlanNode.h` | 节点类＋serde三件套 | §3.3 |
| velox | `velox/experimental/stateful/StatefulPlanner.cpp` | 分派分支 | §3.3 |
| velox | `velox/experimental/stateful/<目录>/<Operator>.h/.cpp` | 新增算子 | §3.2 |
| velox | `velox/experimental/stateful/tests/<Test>.cpp` | 单测 | §7.1 |
| velox4j | `plan/<Node>.java` | 镜像类 | §3.3 |
| gluten | `planner/.../StreamExec<Xxx>.java` | 影子覆盖 | §3.3 |

超出设计影响清单的改动：<无/逐条说明理由（代码评审的致命发现项）>

## 2. 构建与部署

| 环节 | 命令入口 | 结果 | 日志 |
|---|---|---|---|
| 编译（禁跳过C++构建） | flink-velox-build技能 | <成功/失败> | `tmp/<task-name>/logs/cmd-outputs/` |
| 部署与集群重启 | 同上 | <成功/失败> | |

## 3. 单元测试

| 用例组 | 数量 | 通过 | 失败 |
|---|---|---|---|
| appendOnly/INSERT/混合kinds | | | |
| changelog断言 | | | |
| snapshot/restore往返 | | | |
| rescale恢复 | | | |

与设计§7.1矩阵的对应：<逐条对上/缺X条，原因>

失败用例处理：<无/逐条：原因、修复或挂起理由>

## 4. 轻量e2e自测

| 用例 | 输入 | 输出 | 验证方式 | 结果 |
|---|---|---|---|---|
| 冒烟SQL | | | <脚本/人工核对> | |

## 5. 契约自查清单（对照实现契约文档§分步实现）

- [ ] Flink侧transformation保持非keyed
- [ ] 状态只走`HeapKeyedStateBackend`typed API（无旧平面调用）
- [ ] AggregatingState的setAllocator/setOffsets早于首次`rows()`与restore（非Aggregating删本条）
- [ ] 不支持的rowKind fail loud，无静默丢弃
- [ ] 批边界调用`keyedBackend_->advance()`
- [ ] close()逆序：先reset句柄/后端/selector，再调基类
- [ ] 计划约束钉成CHECK（输出schema、不支持语义）

## 6. 通用自查清单

- [ ] 代码与设计方案一致，无超范围改动
- [ ] 无安全规范问题（空指针/越界/注入式拼接等）
- [ ] 单元测试齐全且全部通过，测试可独立运行
- [ ] code format通过
- [ ] 无更简单/更高效的明显替代写法

## 7. 对设计的偏差

<无/逐条：偏差内容＋原因＋是否已回写DESIGN.md或需SPEC变更>
