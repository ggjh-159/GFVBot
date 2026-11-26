# 聚合函数开发快速上手

## 前置条件

```bash
gfvbot install aggregate-function-development   # 装插件（含skills/docs/模板）
gfvbot clone                                    # 四仓克隆到repos/
gfvbot env && gfvbot env-init                   # 环境扫描与补齐
```

装完（或重装后）在项目目录**新开会话**再跑任务：agents只在会话启动时加载，已开的会话看不到新落的`.claude/agents/`；`/agents`能列出5个`aggregate-function-*`即就绪。

首次GFV构建与集群启动由工作流接管：implement阶段走flink-velox-build技能完成编译、部署jars并重启集群，任务前无需手工编译。

聚合设施与测试fixture先行：spec与设计阶段对照`docs/gfvbot/shared/stateful-operator-implementation.md`的聚合相关章节——`makeAggregateInfos`聚合设施、测试SetUp的注册顺序（先prestosql基线、后flinksql覆盖）。注册只走flinksql命名空间，既有聚合实现只扩展不改。

## 示例任务：自定义聚合函数（如COUNT DISTINCT）

一个典型任务——为flinksql命名空间新增一个聚合函数：velox C++ `Aggregate`内核（accumulate/merge/finalize/partial四链路、类型矩阵、NULL与空集语义）、注册条目、单测与nexmark回归：

1. **SPEC**：填`spec.md`模板，可行性评估第一节——既有聚合实现、类型矩阵、注册路径与批处理接入点逐项实证（查不到写"待实证"）
2. **设计**：填`design.md`——现状调研（三段分级＋复用处置）、方案（类型矩阵·中间状态布局·四链路·NULL语义·注册条目）、受影响文件、单测矩阵与nexmark回归集、风险与待裁决
3. **SPEC/设计评审**：reviewer按`review-report.md`出具pass/fail；设计通过后用户门禁1放行
4. **实现**：按设计编码（聚合内核＋注册＋单测fixture）；填`implementation.md`（含场景自查清单）；代码评审通过后用户门禁2放行
5. **验证**：单测（flink-velox-unit-test）＋e2e双跑（flink-velox-e2e-verify，与原生Flink对比折叠后结果集）＋nexmark q17→q15/q16/q4；填`verify.md`；最终验收＋用户门禁3
6. **复盘**：PR.md、SUMMARY.md；涉上游仓时按upstream-contribution模板备草稿，经确认后提交

## 工作流总览

| 阶段 | 负责人 | 门禁 | 关键产物 |
|---|---|---|---|
| spec | architect | SPEC评审pass | architect/SPEC.md |
| design | architect | 设计评审pass＋用户门禁1 | architect/DESIGN.md |
| implement | developer | 代码评审pass＋用户门禁2 | developer/IMPLEMENTATION.md |
| verify | verifier | 最终验收pass＋用户门禁3 | verifier/VERIFY.md |
| retro | architect | 全部产物归档 | developer/PR.md、architect/SUMMARY.md |

任务状态实时记录在`tasks/<任务名>/TASK_STATE.md`（shared模板`docs/gfvbot/shared/templates/task-state.md`），会话中断后从它恢复；阶段内进度看`PROGRESS.md`心跳。

## 提示词模板

`gfvbot prompt aggregate-function-development`打印任务模板；`--task`可让AI代填。
