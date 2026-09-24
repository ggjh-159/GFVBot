# SPEC——<task-name>

## 任务信息

| 项 | 内容 |
|---|---|
| 任务名 | <task-name> |
| 日期 | <YYYY-MM-DD> |
| 来源 | <用户需求原话或issue链接> |
| 目标函数 | `<FUNCTION_NAME>`（类别：<string/temporal/...>） |

## 语义基准

以`docs/gfvbot/shared/flink-expressions/`中该函数的文档卡为唯一语义基准：

| 项 | 内容 |
|---|---|
| 签名 | `<FUNCTION(args)>` |
| 返回类型 | <STRING/INT/...> |
| NULL行为 | <如：任一输入NULL得NULL> |
| 边界行为 | <如：越界下标返回NULL而非报错> |
| Flink源码锚点 | 见文档卡"源码位置"一节 |

## 目标与范围

- 目标：<一句话——该函数在GFV栈上端到端可用>
- 范围内：<velox实现+flinksql注册+gluten映射+单测+e2e>
- 范围外：<如：相关函数族的其他成员、性能调优>

## 验收标准

1. 设计方案通过设计审计（通过/不通过）
2. 单元测试按设计覆盖矩阵全部通过
3. e2e双端比对（原生Flink vs GlutenFlink）全部SQL用例精确一致
4. 既有已映射表达式的e2e用例无回归

## 验证计划

| 层 | 方式 | 入口 |
|---|---|---|
| velox单元测试 | gtest覆盖类型矩阵与NULL/边界 | flink-velox-unit-test技能 |
| 轻量e2e | 自构造输入+print输出+验证脚本 | 实现阶段自测 |
| 全量e2e | 双端跑SQL清单，changelog还原后精确比对 | flink-velox-e2e-verify技能 |
