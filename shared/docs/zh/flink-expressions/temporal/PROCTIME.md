# PROCTIME

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

在DDL中标记处理时间属性；在查询里`PROCTIME()`求值为当前处理时间，类型为TIMESTAMP_LTZ。用于TTL判定、迟数据处理与处理时间的temporal join。

## 用法

输入：`PROCTIME()`——无参数；DDL中写作`AS PROCTIME()`。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, PROCTIME() FROM bid;
```

输出：TIMESTAMP_LTZ；每行被处理时刻的时间戳。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| — | 2026-09-11 10:23:41.209 |

输出每行重新生成（非确定），此处展示一次抽取的值。

## 实现链路

`PROCTIME`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——PROCTIME()——DDL中作属性标记，查询中作函数，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.PROCTIME`（FlinkSqlOperatorTable.java:158）。
2. **定义**——BuiltInFunctionDefinitions.java:2159处的注册条目，注册名`"proctime"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——在DDL中把列声明为处理时间属性；查询体内引用时改写为PROCTIME_MATERIALIZE读取该行的处理时间戳。
4. **代码生成**——ExprCodeGenerator特判——读取当前行的StreamRecord时间戳。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
