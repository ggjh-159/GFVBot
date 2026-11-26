# 性能优化快速上手

## 前置条件

```bash
gfvbot install performance-optimization          # 装插件（含skills/docs/模板）
gfvbot clone                                     # 四仓克隆到repos/
gfvbot env && gfvbot env-init                    # 环境扫描与补齐
```

装完（或重装后）在项目目录**新开会话**再跑任务：agents只在会话启动时加载，已开的会话看不到新落的`.claude/agents/`；`/agents`能列出5个`performance-*`即就绪。

首次GFV构建与集群启动由工作流接管：implement阶段走flink-velox-build技能完成编译、部署jars并重启集群，任务前无需手工编译。

基准环境先行：性能基准参数（1亿events、5000w tps、blackhole、p=1/4/8/16）由flink-velox-performance-verify技能在跑批时自动换入nexmark.yaml与flink-conf并在跑完后恢复，不要手改；集群总槽数（TM数×taskmanager.numberOfTaskSlots）须≥任务的最高档并行度；原生Flink轮与GFV轮之间经flink-velox-build换构建重启集群。GFV只跑object-reuse=false（true会崩溃，脚本硬拦）。

## 示例任务：提升nexmark q17在GFV上的吞吐比值（q17-throughput）

一个典型任务——q17（按seller分组的多聚合）的GFV/原生吞吐比值偏低，定位瓶颈并优化：

1. **SPEC**：analyst经flink-velox-performance-verify跑基线（native r0/r1与gfv r0，p逐档），得`e2e/perf/REPORT.md`比值；填`spec.md`——优化对象与基线比值、目标比值、查询集无回归约束
2. **设计**：填`design.md`——分层定位（比值＋8081 web UI反压/算子状态＋internals地图→归到Java侧/JNI边界/velox C++侧，每条带证据）、方案对比表（收益×风险×改动范围）、受影响文件、复测矩阵与回归集、风险与待裁决
3. **SPEC/设计评审**：reviewer按`review-report.md`出具pass/fail（基线数字须来自REPORT.md、归因须有证据链）；设计通过后用户门禁1放行
4. **实现**：按方案优化（经flink-velox-build编译部署、flink-velox-unit-test跑单测）；填`implementation.md`（含语义不变自查）；代码评审通过后用户门禁2放行
5. **验证**：performance-verify同矩阵复测比值（REPORT.md刷新）＋e2e-verify正确性回归；填`verify.md`；最终验收＋用户门禁3
6. **复盘**：PR.md、SUMMARY.md（含比值变化与经验沉淀建议）；涉上游仓时按upstream-contribution模板备草稿，经确认后提交

## 工作流总览

| 阶段 | 负责人 | 门禁 | 关键产物 |
|---|---|---|---|
| spec | analyst | SPEC评审pass | architect/SPEC.md、`e2e/perf/REPORT.md`（基线） |
| design | analyst | 设计评审pass＋用户门禁1 | architect/DESIGN.md |
| implement | developer | 代码评审pass＋用户门禁2 | developer/IMPLEMENTATION.md |
| verify | verifier | 最终验收pass＋用户门禁3 | verifier/VERIFY.md、`e2e/perf/REPORT.md`（复测） |
| retro | analyst | 全部产物归档 | developer/PR.md、architect/SUMMARY.md |

任务状态实时记录在`tasks/<任务名>/TASK_STATE.md`（shared模板`docs/gfvbot/shared/templates/task-state.md`），会话中断后从它恢复；阶段内进度看`PROGRESS.md`心跳。

## 提示词模板

`gfvbot prompt performance-optimization`打印任务模板；`--task`可让AI代填。
