# NOT_BETWEEN

分类：[比较函数](../index.md#比较函数) · 别名：—

## 定位与场景

`x NOT BETWEEN lo AND hi`是BETWEEN的否定：x在闭区间之外时为TRUE；操作数为NULL时仍得UNKNOWN（并非简单取反）。用于排除某一段取值。

## 用法

输入：`x NOT BETWEEN lo AND hi`——类型规则同BETWEEN；输入为NULL得UNKNOWN。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.price NOT BETWEEN 10.00 AND 60.00 FROM bid;
```

输出：BOOLEAN；`price`低于10.00或高于60.00时为true（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| price | price NOT BETWEEN 10.00 AND 60.00 |
|---|---|
| 55.67 | FALSE |
| 12.50 | FALSE |
| 99.99 | TRUE |
| 3.14 | TRUE |
| 61.20 | TRUE |
| 28.05 | FALSE |
| 77.77 | TRUE |
| 45.00 | FALSE |

## 实现链路

`NOT_BETWEEN`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——NOT BETWEEN..AND关键字，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.NOT_BETWEEN`（FlinkSqlOperatorTable.java:1161）。
2. **定义**——BuiltInFunctionDefinitions.java:580处的注册条目，注册名`"notBetween"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——Sql到Rex转换阶段被改写为SEARCH RexCall（SARG范围）；codegen时由SearchOperatorGen展开为区间比较。
4. **代码生成**——由ExprCodeGenerator内联为普通Java运算代码（ScalarOperatorGens），无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
