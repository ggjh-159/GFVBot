# CARDINALITY

分类：[集合函数](../index.md#集合函数) · 别名：—

## 定位与场景

数组或map的元素个数；输入为NULL得NULL。长度保护与按元素循环的条件。

## 用法

输入：`CARDINALITY(arr_or_map)`——ARRAY或MAP；返回INT。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CARDINALITY(ARRAY[bid.auction, bid.bidder]) FROM bid;
```

输出：INT；每行均为2。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | bidder | CARDINALITY(ARRAY[auction, bidder]) |
|---|---|---|
| 3 | 15 | 2 |
| 19 | 7 | 2 |
| 8 | 8 | 2 |
| 1 | 42 | 2 |
| 14 | 23 | 2 |
| 7 | 2 | 2 |
| 11 | 11 | 2 |
| 20 | 36 | 2 |

## 实现链路

`CARDINALITY`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.CARDINALITY`（FlinkSqlOperatorTable.java:1152）。
2. **定义**——BuiltInFunctionDefinitions.java:1951处的注册条目，注册名`"cardinality"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——由ExprCodeGenerator的CARDINALITY分支内联（读数组/map大小）。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
