# CONVERT_TZ

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

把无时区的时间戳字符串从一个时区换算到另一个时区，返回STRING；时区名取java.util.TimeZone的id。把本地时间数据接入UTC管道或反向转换。

## 用法

输入：`CONVERT_TZ(ts, fromTz, toTz)`——ts为STRING，时区为tz id；返回STRING。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CONVERT_TZ('2026-09-11 10:00:00', 'UTC', 'Asia/Shanghai') FROM bid;
```

输出：STRING；每行均为'2026-09-11 18:00:00'。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| CONVERT_TZ('2026-09-11 10:00:00', 'UTC', 'Asia/Shanghai') | 2026-09-11 18:00:00 |

## 实现链路

`CONVERT_TZ`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.CONVERT_TZ`（FlinkSqlOperatorTable.java:836）。
2. **定义**——BuiltInFunctionDefinitions.java:1852处的注册条目，注册名`"convertTz"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经MethodCallGen调用FunctionGenerator注册的BuiltInMethods静态方法，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
