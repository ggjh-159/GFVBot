# SPLIT_INDEX

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

按分隔符切分s并返回0基第index段；越界或负数下标得NULL。从分隔符字符串中轻量取字段。

## 用法

输入：`SPLIT_INDEX(s, delim, index)`——index为INT，从0起。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, SPLIT_INDEX('a/b/c', '/', 1) FROM bid;
```

输出：STRING；每行均为'b'。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| SPLIT_INDEX('a/b/c', '/', 1) | b |

## 实现链路

`SPLIT_INDEX`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.SPLIT_INDEX`（FlinkSqlOperatorTable.java:451）。
2. **定义**——BuiltInFunctionDefinitions.java:1187处的注册条目，注册名`"splitIndex"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经StringCallGen生成对BuiltInMethods/StringUtils的直调，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
