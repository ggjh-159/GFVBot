# REGEXP_REPLACE

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

把s中每个匹配Java正则的子串替换为replacement。数字脱敏、空白归一、改写日志片段。

## 用法

输入：`REGEXP_REPLACE(s, regex, replacement)`——java.util.regex语义。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, REGEXP_REPLACE(bid.extra, '[0-9]', '#') FROM bid;
```

输出：STRING；`extra`中每个数字替换为'#'（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | REGEXP_REPLACE(extra, '[0-9]', '#') |
|---|---|
| A3F19C27B4E0 | A#F##C##B#E# |
| 8B2D4F90A1C3 | #B#D#F##A#C# |
| C7E5A0D39F16 | C#E#A#D##F## |
| ZK9M2Q7XVBT5 | ZK#M#Q#XVBT# |
| D4C8B1E6A2F7 | D#C#B#E#A#F# |
| 5F0A9D3C7E8B | #F#A#D#C#E#B |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU |
| E2B7F5A9C3D0 | E#B#F#A#C#D# |

## 实现链路

`REGEXP_REPLACE`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.REGEXP_REPLACE`（FlinkSqlOperatorTable.java:468）。
2. **定义**——BuiltInFunctionDefinitions.java:1167处的注册条目，注册名`"regexpReplace"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经StringCallGen生成对BuiltInMethods/StringUtils的直调，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
