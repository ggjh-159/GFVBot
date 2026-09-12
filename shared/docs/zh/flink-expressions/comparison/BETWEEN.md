# BETWEEN

分类：[比较函数](../index.md#比较函数) · 别名：—

## 定位与场景

`x BETWEEN lo AND hi`等价于`x >= lo AND x <= hi`，两端均为闭区间；操作数为NULL时结果为UNKNOWN。价格区间、时间窗口等范围过滤的直观写法。

## 用法

输入：`x BETWEEN lo AND hi`——x、lo、hi为同一可比较类型；输入为NULL得UNKNOWN。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.price BETWEEN 10.00 AND 60.00 FROM bid;
```

输出：BOOLEAN；`price`落在10.00到60.00（含端点）内为true（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| price | price BETWEEN 10.00 AND 60.00 |
|---|---|
| 55.67 | TRUE |
| 12.50 | TRUE |
| 99.99 | FALSE |
| 3.14 | FALSE |
| 61.20 | FALSE |
| 28.05 | TRUE |
| 77.77 | FALSE |
| 45.00 | TRUE |

## 实现链路

`BETWEEN`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——BETWEEN..AND关键字，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.BETWEEN`（FlinkSqlOperatorTable.java:1159）。
2. **定义**——BuiltInFunctionDefinitions.java:564处的注册条目，注册名`"between"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——Sql到Rex转换阶段被改写为SEARCH RexCall（SARG范围）；codegen时由SearchOperatorGen展开为区间比较。
4. **代码生成**——由ExprCodeGenerator内联为普通Java运算代码（ScalarOperatorGens），无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
