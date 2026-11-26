# SPEC — <task-name>

> 按节填写；条目无内容写"无"，不删节。基线比值只引`e2e/perf/REPORT.md`实际产物。

## 任务

- task-name：
- 日期：
- 来源：<任务prompt或需求出处>

## 可行性评估

- 基线可测性：<集群槽数≥最高档并行度、原生与GFV构建均可部署、集群可重启换构建>
- 目标现实性：<目标比值相对基线的差距量级、已知的天花板（如原生reuse=true基线）>
- 复用评估：<可复用的既有优化手段、配置或批处理路径>
- 影响分层：<Java侧（planner翻译/数据桥接） / JNI边界（序列化/Arrow直传） / velox C++侧（算子/表达式/聚合内核）>
- 结论：`feasible` / `feasible with constraints` / `feasible with upstream dependency` / `not feasible`

## 目标与范围

- 目标：<一句话说明优化必须达成什么>
- 范围内：
- 范围外：<新算子/新函数的功能开发默认范围外；工具级profiling无固化skill时写明>

## 优化对象与基线

- 查询集：<q0吞吐基线＋目标查询，选型见nexmark-queries.md>
- 固定基准：<1亿events、5000w tps、blackhole、p=1/4/8/16；native reuse false/true，GFV仅false>
- 基线比值（引`e2e/perf/REPORT.md`基线轮）：

| 查询 | p | GFV/native(r0) | GFV/native(r1) |
|---|---|---|---|
| | | | |

## 目标与约束

- 目标比值或提升幅度：<可判定的取值，如GFV/native(r0)≥0.80>
- 正确性约束：<查询集在原生与GFV双跑结果集一致，不得回归>
- 基准约束：<参数两栈两轮固定；conf由技能换入与恢复，不手改>
- 环境约束：<机器、TM×slots、可用时段>

## 验收标准

- <标准1：复测比值达到目标>
- <标准2：查询集正确性回归全部一致>
- <标准3：基准参数未被改动、作业全部FINISHED>

## 验证计划

- 比值复测：<同矩阵重跑，REPORT.md刷新>
- 正确性回归：<e2e双跑查询集与对比基线>
- 单元测试：<优化改动触及的产品文件对应测试target>
