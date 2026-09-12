# REGEXP_EXTRACT

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

抽取首个正则匹配的第idx个捕获组（0表示整个匹配）；模式不匹配时返回NULL。从半结构化字符串中提取字段。

## 用法

输入：`REGEXP_EXTRACT(s, regex[, idx])`——idx为INT，默认1。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, REGEXP_EXTRACT(bid.extra, '([0-9A-F])', 1) FROM bid;
```

输出：STRING；首个捕获的0-9A-F字符，无匹配为NULL（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | REGEXP_EXTRACT(extra, '([0-9A-F])', 1) |
|---|---|
| A3F19C27B4E0 | A |
| 8B2D4F90A1C3 | 8 |
| C7E5A0D39F16 | C |
| ZK9M2Q7XVBT5 | 9 |
| D4C8B1E6A2F7 | D |
| 5F0A9D3C7E8B | 5 |
| ZZYYXXWWVVUU | NULL |
| E2B7F5A9C3D0 | E |

## 实现链路

`REGEXP_EXTRACT`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.REGEXP_EXTRACT`（FlinkSqlOperatorTable.java:482）。
2. **定义**——BuiltInFunctionDefinitions.java:974处的注册条目，注册名`"regexpExtract"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经StringCallGen生成对BuiltInMethods/StringUtils的直调，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
