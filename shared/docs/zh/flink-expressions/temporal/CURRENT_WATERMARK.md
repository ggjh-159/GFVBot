# CURRENT_WATERMARK

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

返回给定rowtime属性的当前事件时间水位线，类型为TIMESTAMP_LTZ——水位线尚未推进时为NULL；对普通非rowtime列恒为NULL。用于调试水位线进度与编写感知水位线的逻辑；实际使用中该列须声明为事件时间属性。

## 用法

输入：`CURRENT_WATERMARK(rowtime)`——rowtime须为时间属性。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CURRENT_WATERMARK(bid.dateTime) FROM bid;
```

输出：TIMESTAMP_LTZ或NULL；本例每行均为NULL——`dateTime`不是rowtime属性。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| dateTime | CURRENT_WATERMARK(dateTime) |
|---|---|
| 2026-07-03 09:15:22.480 | NULL |
| 2026-07-05 10:41:07.123 | NULL |
| 2026-07-09 11:02:59.640 | NULL |
| 2026-07-03 13:27:44.005 | NULL |
| 2026-07-12 14:50:18.872 | NULL |
| 2026-07-07 15:33:51.309 | NULL |
| 2026-07-09 16:19:36.551 | NULL |
| 2026-07-11 17:44:29.918 | NULL |

## 实现链路

`CURRENT_WATERMARK`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数CURRENT_WATERMARK(rowtime)，FlinkSqlOperatorTable无专属常量——调用经FunctionDefinitionOperatorTable解析，它把BuiltInFunctionDefinitions条目即时适配为SqlFunction。
2. **定义**——BuiltInFunctionDefinitions.java:2181处的注册条目，注册名`"CURRENT_WATERMARK"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——ExprCodeGenerator特判——读取输入StreamRecord上下文的当前水位线。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
