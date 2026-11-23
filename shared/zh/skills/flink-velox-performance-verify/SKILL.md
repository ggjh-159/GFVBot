---
name: flink-velox-performance-verify
description: 以nexmark固定基准（1亿events、5000w tps、blackhole、p=1/4/8/16）在原生Flink与GFV上重放同一组查询，输出GFV/原生吞吐比值与耗时对比报告。
---

# Flink-velox性能验证

对同一组nexmark查询在原生Flink与GFV两栈上重放，量化GFV/原生性能比值。

## 何时使用

量化GFV与原生的性能差距：同一查询集在两栈各跑一轮，输出各查询各并行度下GFV相对原生的吞吐比值。

对比对象是原生而非GFV优化前——优化前的构建可能根本不支持待实现的算子，SQL跑不起来，比值无从谈起；原生Flink始终具备全部语义。

## 运行矩阵与铁律

| 轮 | 构建 | pipeline.object-reuse | 说明 |
|---|---|---|---|
| native r0 | 原生Flink | false | 基线一 |
| native r1 | 原生Flink | true | 基线二；与r0间只改conf，不需重启集群 |
| gfv r0 | GFV | false | **GFV禁用object-reuse=true——会崩溃**，脚本硬拦 |

固定基准参数（两栈两轮完全一致，数字才可比）：

- 数据量1亿events、生成速率5000w tps、sink为blackhole（查询DDL自带）。
- 并行度p=1/4/8/16逐档跑，档内两栈同一p才可比。
- 参数由脚本落位：nexmark.yaml整份换入skill自备固定版（conf/nexmark-gfv.yaml）、flink-conf写入parallelism.default与pipeline.object-reuse，**跑完自动恢复原件**（失败/中断也恢复）。
- 总槽数（TM数×taskmanager.numberOfTaskSlots）须≥p，不足脚本拦截并指引先调slots重启集群。

## 证据树：`e2e/perf/`在项目根，不按任务收纳

与`e2e/{sql,data,out,verify}`同理：捕获是运行证据、报告是裁决依据，跨任务沉淀，最新一轮原地刷新：

```
e2e/perf/
  native/   qNN.p<P>.r0.out         原生reuse=false指标表（提取自submit.log）
            qNN.p<P>.r1.out         原生reuse=true指标表
            *.submit.log            runner完整输出（随out自动生成）
  gfv/      qNN.p<P>.r0.out         GFV指标表（仅reuse=false）
            *.submit.log
  REPORT.md                          GFV/原生比值报告（原地刷新）
```

## 流程

1. 定查询集：q0（吞吐基线）＋目标查询，全集与选型见docs/nexmark-queries.md。
2. native轮（r0与r1、p逐档）：`bin/run-perf.sh native qNN <p> false e2e/perf/native/qNN.p<P>.r0.out`；reuse=true轮把第4参换true、产物名换r1。
3. 经flink-velox-build换GFV构建重启集群。
4. GFV轮（仅r0、p逐档）：`bin/run-perf.sh gfv qNN <p> false e2e/perf/gfv/qNN.p<P>.r0.out`。
5. 报告落档：`bin/perf_report.py e2e/perf/native e2e/perf/gfv > e2e/perf/REPORT.md`（模板在references/report-template.md，结构固定），agent补报告头部占位（日期、构建标识、环境）。

## 对比标准

只报数据不下机械结论：各查询各档GFV/原生吞吐比值（对r0、r1两个基线各一列）、耗时对比，events数不一致的行标注不可比及原因；结论由人结合比值幅度与环境噪声给出。作业须到FINISHED，指标表才算数。
