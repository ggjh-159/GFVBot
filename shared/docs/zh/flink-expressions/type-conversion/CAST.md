# CAST

分类：[类型转换函数](../index.md#类型转换函数) · 别名：—

## 定位与场景

显式类型转换，覆盖很宽的矩阵——数值的拓宽与收窄、字符串与数值互转、字符串与时间互转、复合类型的重标注。无法转换时抛运行时错误。

## 用法

输入：`CAST(x AS t)`——t为具体SQL类型。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CAST(bid.auction AS VARCHAR) FROM bid;
```

输出：VARCHAR；每行`auction`的十进制数字（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | CAST(auction AS VARCHAR) |
|---|---|
| 3 | 3 |
| 19 | 19 |
| 8 | 8 |
| 1 | 1 |
| 14 | 14 |
| 7 | 7 |
| 11 | 11 |
| 20 | 20 |

## 实现链路

`CAST`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——CAST(x AS t)，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.CAST`（FlinkSqlOperatorTable.java:1194）。
2. **定义**——BuiltInFunctionDefinitions.java:2390处的注册条目，注册名`"cast"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——ExprCodeGenerator的CAST分支按源/目标类型对生成专用转换代码（数值/字符串/时间矩阵）。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
