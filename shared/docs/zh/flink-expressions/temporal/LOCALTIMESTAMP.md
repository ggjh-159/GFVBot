# LOCALTIMESTAMP

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

当前时刻的TIMESTAMP（无时区），每查询求值一次，不带括号。面向展示的本地钟面时间。

## 用法

输入：`LOCALTIMESTAMP`——不带括号；TIMESTAMP。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, LOCALTIMESTAMP FROM bid;
```

输出：TIMESTAMP；查询开始时的本地钟面时间，16行完全相同。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| — | 2026-09-11 10:23:41.209 |

每查询求值一次，16行同值。

## 实现链路

`LOCALTIMESTAMP`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——关键字，不带括号，FlinkSqlOperatorTable无专属常量——调用经FunctionDefinitionOperatorTable解析，它把BuiltInFunctionDefinitions条目即时适配为SqlFunction。
2. **定义**——BuiltInFunctionDefinitions.java:1794处的注册条目，注册名`"localTimestamp"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——CurrentTimePointCallGen——流模式下作为查询级常量注入可复用成员；批模式在规划期折叠。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
