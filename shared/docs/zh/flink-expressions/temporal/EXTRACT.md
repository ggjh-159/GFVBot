# EXTRACT

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

抽取一个日期时间字段——YEAR、QUARTER、MONTH、WEEK、DAY、DOY、DOW、HOUR、MINUTE、SECOND——返回整数。按时间桶分组与派生日历特征。

## 用法

输入：`EXTRACT(field FROM ts)`——ts为DATE/TIME/TIMESTAMP（或间隔）；返回BIGINT。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, EXTRACT(DAY FROM bid.dateTime) FROM bid;
```

输出：BIGINT；`dateTime`的日，每行1-31（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| dateTime | EXTRACT(DAY FROM dateTime) |
|---|---|
| 2026-07-03 09:15:22.480 | 3 |
| 2026-07-05 10:41:07.123 | 5 |
| 2026-07-09 11:02:59.640 | 9 |
| 2026-07-03 13:27:44.005 | 3 |
| 2026-07-12 14:50:18.872 | 12 |
| 2026-07-07 15:33:51.309 | 7 |
| 2026-07-09 16:19:36.551 | 9 |
| 2026-07-11 17:44:29.918 | 11 |

## 实现链路

`EXTRACT`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——标准EXTRACT(field FROM ts)，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.EXTRACT`（FlinkSqlOperatorTable.java:1170）。
2. **定义**——BuiltInFunctionDefinitions.java:1732处的注册条目，注册名`"extract"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——ExtractCallGen调BuiltInMethods.UNIX_DATE_EXTRACT（带时区时间戳走EXTRACT_FROM_TIMESTAMP_TIME_ZONE）。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
