# CEIL

分类：[算术函数](../index.md#算术函数) · 别名：`CEILING`

## 定位与场景

不小于x的最小整数；CEILING为同义拼法。`CEIL(ts TO unit)`把时间戳向上取整到单位边界。容量向上取整——分页、批次、计费块。

## 用法

输入：`CEIL(x)`或`CEILING(x)`——数值；`CEIL(ts TO unit)`——时间。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CEIL(bid.price) FROM bid;
```

输出：每行向上取整到下一个整数的十进制值，如55.01变56。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| price | CEIL(price) |
|---|---|
| 55.67 | 56 |
| 12.50 | 13 |
| 99.99 | 100 |
| 3.14 | 4 |
| 61.20 | 62 |
| 28.05 | 29 |
| 77.77 | 78 |
| 45.00 | 45 |

## 实现链路

`CEIL`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式（CEILING为别名），解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.CEIL`（FlinkSqlOperatorTable.java:1193）。
2. **定义**——BuiltInFunctionDefinitions.java:1418处的注册条目，注册名`"ceil"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——FloorCeilCallGen——数值走BuiltInMethods.FLOOR/CEIL，时间截断走UNIX_DATE/UNIX_TIMESTAMP系列helper。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
