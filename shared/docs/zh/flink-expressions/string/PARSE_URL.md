# PARSE_URL

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

抽取URL的一个部分——PROTOCOL、HOST、PATH、QUERY、REF、AUTHORITY或FILE；带key参数时返回该查询参数。日志与来源分析。

## 用法

输入：`PARSE_URL(url, part[, key])`——url、part为STRING，key为STRING。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, PARSE_URL('http://h/p?a=1#f', 'QUERY', 'a') FROM bid;
```

输出：STRING；每行均为'1'（查询参数a的值）。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| PARSE_URL('http://h/p?a=1#f', 'QUERY', 'a') | 1 |

## 实现链路

`PARSE_URL`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.PARSE_URL`（FlinkSqlOperatorTable.java:611）。
2. **定义**——BuiltInFunctionDefinitions.java:1094处的注册条目，注册名`"parseUrl"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经StringCallGen生成对BuiltInMethods/StringUtils的直调，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
