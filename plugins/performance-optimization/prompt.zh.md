# 任务prompt——性能提升

在目标项目的AI Agent（Claude Code / opencode）中粘贴以下内容，填好<占位符>后发送。

优化`<对象>`并用测量数据闭环。

- 目标：<优化什么：一条query、一个算子或一段pipeline；症状是什么，如慢查询、CPU高>
- 验证：<前后各跑一次的基准，如nexmark query `<qNN>`耗时；profiling手段，如flamegraph>
- 验收：<做到什么程度算完成：如延迟或吞吐提升<N>、<query集合>无正确性回归>
- 补充：<其他需要Agent知道的背景：疑似瓶颈、已有profiling结论、约束>

按已安装的performance-optimization工作流推进，从SPEC阶段开始。
