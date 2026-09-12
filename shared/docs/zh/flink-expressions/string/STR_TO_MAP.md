# STR_TO_MAP

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

以pairDelim分隔键值对、kvDelim分隔键与值，把s解析成MAP。把序列化的标签串或参数串还原成可查询的map。

## 用法

输入：`STR_TO_MAP(s[, pairDelim[, kvDelim]])`——分隔符为STRING。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, STR_TO_MAP('a=1,b=2', ',', '=') FROM bid;
```

输出：MAP<STRING, STRING>；每行均为{a=1, b=2}。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| STR_TO_MAP('a=1,b=2', ',', '=') | {a=1, b=2} |

## 实现链路

`STR_TO_MAP`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.STR_TO_MAP`（FlinkSqlOperatorTable.java:321）。
2. **定义**——BuiltInFunctionDefinitions.java:1199处的注册条目，注册名`"strToMap"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经StringCallGen生成对BuiltInMethods/StringUtils的直调，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
