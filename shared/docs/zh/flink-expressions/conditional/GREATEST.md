# GREATEST

分类：[条件函数](../index.md#条件函数) · 别名：—

## 定位与场景

返回参数中的最大值；任一参数为NULL则结果为NULL。常用于跨列归一化与钳制（如给计算结果兜一个下限）。

## 用法

输入：`GREATEST(v1, v2, ...)`——两个及以上同类型可比较的值。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, GREATEST(bid.auction, bid.bidder, 7) FROM bid;
```

输出：BIGINT；每行取`auction`、`bidder`与常量7三者中的最大值。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | bidder | GREATEST(auction, bidder, 7) |
|---|---|---|
| 3 | 15 | 15 |
| 19 | 7 | 19 |
| 8 | 8 | 8 |
| 1 | 42 | 42 |
| 14 | 23 | 23 |
| 7 | 2 | 7 |
| 11 | 11 | 11 |
| 20 | 36 | 36 |

## 实现链路

`GREATEST`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，FlinkSqlOperatorTable无专属常量——调用经FunctionDefinitionOperatorTable解析，它把BuiltInFunctionDefinitions条目即时适配为SqlFunction。
2. **定义**——BuiltInFunctionDefinitions.java:596处的注册条目，注册名`"GREATEST"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——ExprCodeGenerator的BridgingSqlFunction分支经generateGreatestLeast内联为逐参数比较链，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
