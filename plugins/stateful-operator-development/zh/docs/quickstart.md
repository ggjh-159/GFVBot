# 有状态算子开发快速上手

## 前置条件

```bash
gfvbot install stateful-operator-development   # 装插件（含skills/docs/模板）
gfvbot clone                                   # 四仓克隆到repos/
gfvbot env && gfvbot env-init                  # 环境扫描与补齐
```

装完（或重装后）在项目目录**新开会话**再跑任务：agents只在会话启动时加载，已开的会话看不到新落的`.claude/agents/`；`/agents`能列出5个`stateful-operator-*`即就绪。

首次GFV构建与集群启动由工作流接管：implement阶段走flink-velox-build技能完成编译、部署jars并重启集群，任务前无需手工编译。

实现契约先行：spec与设计阶段全程对照`docs/gfvbot/shared/stateful-operator-implementation.md`——后端保证、状态句柄选型、生命周期范式（六步建后端、七步addInput）与陷阱清单。

## 示例任务：流式去重算子（Deduplication）

一个典型任务——按key去重、仅首条输出（+I），后续重复丢弃，状态用ValueState存已见标记：

1. **SPEC**：填`spec.md`模板，可行性评估第一节，对照实现契约文档逐项核对（ValueState句柄、无partition语义用VoidNamespace）
2. **设计**：填`design.md`——现状调研（planner分派链、既有节点类）、契约对照（句柄选型、六步/七步落位、非keyed铁律）、受影响三仓文件、单测矩阵（appendOnly/kinds/changelog/snapshot往返/rescale）、风险对照陷阱表
3. **SPEC/设计评审**：reviewer按`review-report.md`出具pass/fail；设计通过后用户门禁1放行
4. **实现**：按设计编码（velox节点＋算子＋planner分支＋单测、velox4j镜像、gluten影子覆盖）；填`implementation.md`（含契约自查清单）；代码评审通过后用户门禁2放行
5. **验证**：单测（flink-velox-unit-test）＋e2e（flink-velox-e2e-verify，与原生Flink对比changelog）；填`verify.md`；最终验收＋用户门禁3
6. **复盘**：PR.md、SUMMARY.md；涉上游仓时按upstream-contribution模板备草稿，经确认后提交

## 工作流总览

| 阶段 | 负责人 | 门禁 | 关键产物 |
|---|---|---|---|
| spec | architect | SPEC评审pass | architect/SPEC.md |
| design | architect | 设计评审pass＋用户门禁1 | architect/DESIGN.md |
| implement | developer | 代码评审pass＋用户门禁2 | developer/IMPLEMENTATION.md |
| verify | verifier | 最终验收pass＋用户门禁3 | verifier/VERIFY.md |
| retro | architect | 全部产物归档 | developer/PR.md、architect/SUMMARY.md |

任务状态实时记录在`tasks/<任务名>/TASK_STATE.md`（模板`task-state.md`），会话中断后从它恢复；阶段内进度看`PROGRESS.md`心跳。

## 提示词模板

`gfvbot prompt stateful-operator-development`打印任务模板；`--task`可让AI代填。
