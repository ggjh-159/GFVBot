# TIMESTAMPDIFF

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

以指定单位——SECOND、MINUTE、HOUR、DAY、MONTH或YEAR（月/年差按日历计算）——表示的整数差t2减t1。延迟、时龄与时长的计算。

## 用法

输入：`TIMESTAMPDIFF(unit, t1, t2)`——t1、t2为同类时间类型；返回BIGINT。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, TIMESTAMPDIFF(SECOND, bid.dateTime, bid.dateTime) FROM bid;
```

输出：BIGINT；每行均为0——两侧是同一个时间戳。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| dateTime | TIMESTAMPDIFF(SECOND, dateTime, dateTime) |
|---|---|
| 2026-07-03 09:15:22.480 | 0 |
| 2026-07-05 10:41:07.123 | 0 |
| 2026-07-09 11:02:59.640 | 0 |
| 2026-07-03 13:27:44.005 | 0 |
| 2026-07-12 14:50:18.872 | 0 |
| 2026-07-07 15:33:51.309 | 0 |
| 2026-07-09 16:19:36.551 | 0 |
| 2026-07-11 17:44:29.918 | 0 |

## 实现链路

`TIMESTAMPDIFF`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.TIMESTAMP_DIFF`（FlinkSqlOperatorTable.java:1222）。
2. **定义**——BuiltInFunctionDefinitions.java:1832处的注册条目，注册名`"timestampDiff"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——TimestampDiffCallGen——按日历语义对两个时间做单位差运算。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
