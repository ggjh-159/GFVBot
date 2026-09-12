# UNARY_MINUS

分类：[算术函数](../index.md#算术函数) · 别名：`-x`

## 定位与场景

数值的一元取负。把指标符号翻转，让差值方向更直观（亏损、迟到等）。

## 用法

输入：`-x`——x为任意数值类型；NULL仍为NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, -bid.auction FROM bid;
```

输出：BIGINT；每行取负的`auction`。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | -auction |
|---|---|
| 3 | -3 |
| 19 | -19 |
| 8 | -8 |
| 1 | -1 |
| 14 | -14 |
| 7 | -7 |
| 11 | -11 |
| 20 | -20 |

## 实现链路

`UNARY_MINUS`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——前缀-x，FlinkSqlOperatorTable无专属常量——调用经FunctionDefinitionOperatorTable解析，它把BuiltInFunctionDefinitions条目即时适配为SqlFunction。
2. **定义**——BuiltInFunctionDefinitions.java:1504处的注册条目，注册名`"minusPrefix"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——由ExprCodeGenerator内联为普通Java运算代码（ScalarOperatorGens），无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
