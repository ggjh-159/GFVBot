# SPEC — <task-name>

## 任务

- task-name：
- 日期：
- 来源：<任务prompt或需求出处>

## 可行性评估

- velox C++侧对目标语义的支持度：<算子/函数名称与版本>
- Flink到velox的语义匹配：<完全匹配/部分匹配/需补偿，及差距说明>
- 复用评估：<可复用/可扩展/需新建的既有代码>
- 影响分层：<planner / runtime / velox experimental stateful / velox4j>
- 结论：`feasible` / `feasible with constraints` / `feasible with upstream dependency` / `not feasible`

## 目标与范围

- 目标：<一句话说明算子必须完成什么>
- 范围内：
- 范围外：

## 接口规格

- 算子/函数面：<名称、输入输出类型>
- 配置项：<选项与默认值>
- 跨层契约：<planner交给runtime什么、runtime交给bridge什么>

## 行为规格

- 触发与节奏：<算子何时触发，逐记录/逐watermark/逐timer>
- 状态访问：<读写哪些状态、key形态、生命周期>
- watermark与timer语义：<watermark如何推进算子、timer行为>
- 输出：<产出的行与schema、顺序保证>
- 边界行为：<空输入、null、迟到数据、状态规模上界>

## 验收标准

- <标准1：可验证的陈述，如与指定基线的输出一致性>
- <标准2：不得回归的查询或测试>
- <标准3：状态或性能边界（如有）>

## 验证计划

- 单元测试：<测试target与钉住的行为>
- 端到端：<要跑的查询或工作负载、对比基线>
- 回归：<需要复检的共用组件>
