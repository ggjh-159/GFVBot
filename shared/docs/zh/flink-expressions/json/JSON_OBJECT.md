# JSON_OBJECT

分类：[JSON函数](../index.md#JSON函数) · 别名：—

## 定位与场景

由KEY VALUE对构造JSON对象；NULL ON NULL保留NULL值，ABSENT ON NULL将其省略。把列数据组装成事件载荷。

## 用法

输入：`JSON_OBJECT([k VALUE v, ...] [NULL ON NULL | ABSENT ON NULL])`——键为STRING字面量。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_OBJECT('k' VALUE 42) FROM bid;
```

输出：STRING；每行均为'{"k":42}'。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| JSON_OBJECT('k' VALUE 42) | {"k":42} |

## 实现链路

`JSON_OBJECT`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.JSON_OBJECT`（FlinkSqlOperatorTable.java:1249）。
2. **定义**——BuiltInFunctionDefinitions.java:2305处的注册条目，注册名`"JSON_OBJECT"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——专属JsonObjectCallGen。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
