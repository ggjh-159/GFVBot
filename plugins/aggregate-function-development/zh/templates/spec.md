# SPEC — <task-name>

> 按节填写；条目无内容写"无"，不删节。

## 任务

- task-name：
- 日期：
- 来源：<任务prompt或需求出处>

## 可行性评估

- velox C++侧既有聚合与可扩展实现：<函数/类名与版本，经源码或文档实证；查不到写"待实证">
- 类型支持与类型矩阵：<目标输入类型在velox与Flink两侧的支持与差距>
- 注册路径：<flinksql命名空间聚合注册的落位；与prestosql同名覆盖关系>
- 批处理接入点：<聚合设施`makeAggregateInfos`与RowContainer行的接入现状>
- 结论：`feasible` / `feasible with constraints` / `feasible with upstream dependency` / `not feasible`

## 目标与范围

- 目标：<一句话说明聚合函数必须完成什么>
- 范围内：
- 范围外：<聚合算子（GroupAggregator/WindowAggregator）默认范围外>

## 接口规格

- 函数签名：<SQL函数名、参数类型矩阵、返回类型>
- 注册条目：<命名空间、注册文件与条目形态>
- 跨层契约：<planner翻译到runtime批处理暴露的路径>

## 行为规格

- accumulate语义：<逐行累加到中间状态的行为>
- partial/merge语义：<分片中间结果提取与合并的行为>
- finalize语义：<中间状态到最终输出的行为>
- NULL与空集：<NULL输入、全NULL、空集的输出>
- 边界行为：<溢出、精度、超大基数>

## 验收标准

- <标准1：与原生Flink对同一输入的聚合结果一致性>
- <标准2：不得回归的nexmark聚合查询或既有单测>
- <标准3：类型矩阵全覆盖>

## 验证计划

- 单元测试：<测试target与钉住的行为（类型矩阵/NULL/partial往返）>
- 端到端：<双跑用例与对比基线；nexmark q17起步，按改动拓宽到q15/q16/q4>
- 回归：<需要复检的既有聚合与共用聚合设施>
