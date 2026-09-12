# TEMPORAL_OVERLAPS

分类：[时间函数](../index.md#时间函数) · 别名：`OVERLAPS`

## 定位与场景

判断两个时间区间是否有公共时刻：`(s1, e1) OVERLAPS (s2, e2)`；每侧可为（起，止）或（起，时长）。常用于排班冲突检测与窗口重叠判断。

## 用法

输入：`(s1, e1 | iv1) OVERLAPS (s2, e2 | iv2)`——端点为时间类型，或起点加INTERVAL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.dateTime, INTERVAL '1' HOUR) OVERLAPS (bid.dateTime, INTERVAL '1' DAY) FROM bid;
```

输出：BOOLEAN；本例恒为true——两窗口同起于`dateTime`，1小时的窗口被1天的窗口完全包含。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| dateTime | (dateTime, 1h) OVERLAPS (dateTime, 1d) |
|---|---|
| 2026-07-03 09:15:22.480 | TRUE |
| 2026-07-05 10:41:07.123 | TRUE |
| 2026-07-09 11:02:59.640 | TRUE |
| 2026-07-03 13:27:44.005 | TRUE |
| 2026-07-12 14:50:18.872 | TRUE |
| 2026-07-07 15:33:51.309 | TRUE |
| 2026-07-09 16:19:36.551 | TRUE |
| 2026-07-11 17:44:29.918 | TRUE |

## 实现链路

`TEMPORAL_OVERLAPS`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——中缀(s1, e1) OVERLAPS (s2, e2)，FlinkSqlOperatorTable无专属常量——调用经FunctionDefinitionOperatorTable解析，它把BuiltInFunctionDefinitions条目即时适配为SqlFunction。
2. **定义**——BuiltInFunctionDefinitions.java:1801处的注册条目，注册名`"temporalOverlaps"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——SqlNode到Rex转换时经TemporalOverlapsConverter（planner/expressions/converter/converters）把OVERLAPS展开为对区间边界的AND/OR比较树。
4. **代码生成**——由ExprCodeGenerator内联为普通Java运算代码（ScalarOperatorGens），无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
