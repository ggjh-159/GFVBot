# DATE_FORMAT

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

用Java SimpleDateFormat风格的模式（如yyyy-MM-dd HH:mm:ss）格式化时间戳（或时间字符串），返回STRING。报表与分区列的定宽时间标签。

## 用法

输入：`DATE_FORMAT(ts, pattern)`——ts为TIMESTAMP/TIMESTAMP_LTZ/STRING，pattern为STRING。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, DATE_FORMAT(bid.dateTime, 'yyyy-MM-dd HH:mm:ss') FROM bid;
```

输出：STRING；每行按给定模式渲染的`dateTime`（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| dateTime | DATE_FORMAT(dateTime, 'yyyy-MM-dd HH:mm:ss') |
|---|---|
| 2026-07-03 09:15:22.480 | 2026-07-03 09:15:22 |
| 2026-07-05 10:41:07.123 | 2026-07-05 10:41:07 |
| 2026-07-09 11:02:59.640 | 2026-07-09 11:02:59 |
| 2026-07-03 13:27:44.005 | 2026-07-03 13:27:44 |
| 2026-07-12 14:50:18.872 | 2026-07-12 14:50:18 |
| 2026-07-07 15:33:51.309 | 2026-07-07 15:33:51 |
| 2026-07-09 16:19:36.551 | 2026-07-09 16:19:36 |
| 2026-07-11 17:44:29.918 | 2026-07-11 17:44:29 |

## 实现链路

`DATE_FORMAT`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.DATE_FORMAT`（FlinkSqlOperatorTable.java:591）。
2. **定义**——BuiltInFunctionDefinitions.java:1817处的注册条目，注册名`"dateFormat"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经MethodCallGen调用FunctionGenerator注册的BuiltInMethods静态方法，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
