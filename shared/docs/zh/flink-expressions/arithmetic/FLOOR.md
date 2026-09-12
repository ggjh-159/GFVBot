# FLOOR

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

不大于x的最大整数。时间形式`FLOOR(ts TO unit)`把时间戳向下截断到指定单位边界（HOUR、DAY、MONTH等）。用于对齐到桶边界。

## 用法

输入：`FLOOR(x)`——数值；`FLOOR(ts TO unit)`——时间。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, FLOOR(bid.price) FROM bid;
```

输出：每行去掉小数部分的十进制值，如55.67变55。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| price | FLOOR(price) |
|---|---|
| 55.67 | 55 |
| 12.50 | 12 |
| 99.99 | 99 |
| 3.14 | 3 |
| 61.20 | 61 |
| 28.05 | 28 |
| 77.77 | 77 |
| 45.00 | 45 |

## 实现链路

`FLOOR`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.FLOOR`（FlinkSqlOperatorTable.java:1192）。
2. **定义**——BuiltInFunctionDefinitions.java:1401处的注册条目，注册名`"floor"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——FloorCeilCallGen——数值走BuiltInMethods.FLOOR/CEIL，时间截断走UNIX_DATE/UNIX_TIMESTAMP系列helper。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
