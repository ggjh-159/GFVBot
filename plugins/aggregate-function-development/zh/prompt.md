# 任务prompt——聚合函数开发

在目标项目的AI Agent（Claude Code / opencode）中粘贴以下内容，填好<占位符>后发送。

实现`<聚合函数>`聚合函数：velox Aggregate及其accumulate / merge / finalize链路，并接入批处理执行。

- 目标：<聚合语义：输入类型、输出类型、中间状态布局>
- 验证：<如何确认正确性：使用该聚合的批式与流式SQL、accumulate/merge/finalize链路的单元测试>
- 验收：<做到什么程度算完成：结果与Flink原生聚合器一致、批式与流式路径结果一致>
- 补充：<其他需要Agent知道的背景：可参照的同类聚合、状态大小考量>

按已安装的aggregate-function-development工作流推进，从SPEC阶段开始。
