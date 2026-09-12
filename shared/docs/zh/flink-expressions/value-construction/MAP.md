# MAP

分类：[值构造函数](../index.md#值构造函数) · 别名：—

## 定位与场景

map构造器`MAP[k1, v1, k2, v2, ...]`——键值交替书写；键与值各自统一类型。小型内联查找表。

## 用法

输入：`MAP[k1, v1, k2, v2, ...]`——键同型，值同型。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, MAP['k1', bid.auction, 'k2', bid.bidder] FROM bid;
```

输出：MAP<STRING, BIGINT>；每行为`{k1=auction, k2=bidder}`。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | bidder | MAP['k1', auction, 'k2', bidder] |
|---|---|---|
| 3 | 15 | {k1=3, k2=15} |
| 19 | 7 | {k1=19, k2=7} |
| 8 | 8 | {k1=8, k2=8} |
| 1 | 42 | {k1=1, k2=42} |
| 14 | 23 | {k1=14, k2=23} |
| 7 | 2 | {k1=7, k2=2} |
| 11 | 11 | {k1=11, k2=11} |
| 20 | 36 | {k1=20, k2=36} |

## 实现链路

`MAP`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——MAP[k, v, ..]构造器，FlinkSqlOperatorTable无专属常量——调用经FunctionDefinitionOperatorTable解析，它把BuiltInFunctionDefinitions条目即时适配为SqlFunction。
2. **定义**——BuiltInFunctionDefinitions.java:1980处的注册条目，注册名`"map"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——由ExprCodeGenerator的MAP_VALUE_CONSTRUCTOR分支内联为GenericMapData构造。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
