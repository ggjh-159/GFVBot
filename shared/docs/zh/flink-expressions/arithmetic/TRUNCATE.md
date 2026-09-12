# TRUNCATE

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

把x在d位小数处截断（默认0），不做四舍五入——超出d位的数字直接丢弃。当ROUND的half-up会高估时，TRUNCATE保持保守。

## 用法

输入：`TRUNCATE(x, d)`或`TRUNCATE(x)`——x为数值，d为非负整数字面量。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, TRUNCATE(bid.price, 1) FROM bid;
```

输出：每行在1位小数处截断的十进制值，如55.67变55.6。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| price | TRUNCATE(price, 1) |
|---|---|
| 55.67 | 55.6 |
| 12.50 | 12.5 |
| 99.99 | 99.9 |
| 3.14 | 3.1 |
| 61.20 | 61.2 |
| 28.05 | 28.0 |
| 77.77 | 77.7 |
| 45.00 | 45.0 |

## 实现链路

`TRUNCATE`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.TRUNCATE`（FlinkSqlOperatorTable.java:279）。
2. **定义**——BuiltInFunctionDefinitions.java:1703处的注册条目，注册名`"truncate"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经MethodCallGen调用FunctionGenerator注册的BuiltInMethods静态方法，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
