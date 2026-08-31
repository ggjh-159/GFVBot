# 任务prompt——无状态表达式开发

在目标项目的AI Agent（Claude Code / opencode）中粘贴以下内容，填好<占位符>后发送。

实现`<函数>`无状态表达式，在velox、velox4j、gluten-flink三层端到端接入。

- 目标：<表达式语义：输入类型、输出类型、边界情况>
- 验证：<如何确认正确性：覆盖该表达式的SQL query、各层单元测试>
- 验收：<做到什么程度算完成：结果与Flink原生实现一致、三层测试全过>
- 补充：<其他需要Agent知道的背景：可参照的同类函数、特殊用例>

按已安装的stateless-expression-development工作流推进，从SPEC阶段开始。
