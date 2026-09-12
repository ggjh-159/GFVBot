# TYPEOF

分类：[类型转换函数](../index.md#类型转换函数) · 别名：—

## 定位与场景

把参数的运行时类型作为STRING返回（如`BIGINT NOT NULL`）；可选force标志按原样求参数的SQL文本。调试动态schema下的类型推导。

## 用法

输入：`TYPEOF(x)`或`TYPEOF(x, force)`——任意输入；返回STRING。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, TYPEOF(bid.auction) FROM bid;
```

输出：STRING；每行均为'BIGINT NOT NULL'。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | TYPEOF(auction) |
|---|---|
| 3 | BIGINT NOT NULL |
| 19 | BIGINT NOT NULL |
| 8 | BIGINT NOT NULL |
| 1 | BIGINT NOT NULL |
| 14 | BIGINT NOT NULL |
| 7 | BIGINT NOT NULL |
| 11 | BIGINT NOT NULL |
| 20 | BIGINT NOT NULL |

## 实现链路

`TYPEOF`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，FlinkSqlOperatorTable无专属常量——调用经FunctionDefinitionOperatorTable解析，它把BuiltInFunctionDefinitions条目即时适配为SqlFunction。
2. **定义**——BuiltInFunctionDefinitions.java:114处的注册条目，注册名`"TYPEOF"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经BridgingSqlFunctionCallGen调用table-runtime类scalar/TypeOfFunction的eval()（flink-table-runtime，新栈载体）。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
