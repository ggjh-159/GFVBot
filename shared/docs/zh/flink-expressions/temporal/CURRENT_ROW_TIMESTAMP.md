# CURRENT_ROW_TIMESTAMP

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

求值时逐行读取的TIMESTAMP_LTZ时钟——而CURRENT_TIMESTAMP每查询固定。Flink 1.19中必须带括号，否则解析器会当作列名。用于摄入时间打标。

## 用法

输入：`CURRENT_ROW_TIMESTAMP()`——必须带括号；TIMESTAMP_LTZ。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CURRENT_ROW_TIMESTAMP() FROM bid;
```

输出：TIMESTAMP_LTZ；每行重新读取。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| — | 2026-09-11 10:23:41.209 |

输出每行重新生成（非确定），此处展示一次抽取的值。

## 实现链路

`CURRENT_ROW_TIMESTAMP`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，必须带括号，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.CURRENT_ROW_TIMESTAMP`（FlinkSqlOperatorTable.java:635）。
2. **定义**——BuiltInFunctionDefinitions.java:1786处的注册条目，注册名`"currentRowTimestamp"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——标记为非确定，规划期既不折叠也不跨算子移动。
4. **代码生成**——CurrentTimePointCallGen的逐行模式——每行读取时钟。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
