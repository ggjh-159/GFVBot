# SUBSTRING

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

从s的1基位置n开始取m个字符；省略FOR m时取到串尾。最常用的字段切片表达式。

## 用法

输入：`SUBSTRING(s FROM n [FOR m])`或`SUBSTRING(s, n [, m])`——n、m为整数。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, SUBSTRING(bid.extra FROM 2 FOR 5) FROM bid;
```

输出：STRING；每行取`extra`的第2到6个字符（共5个）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | SUBSTRING(extra FROM 2 FOR 5) |
|---|---|
| A3F19C27B4E0 | 3F19C |
| 8B2D4F90A1C3 | B2D4F |
| C7E5A0D39F16 | 7E5A0 |
| ZK9M2Q7XVBT5 | K9M2Q |
| D4C8B1E6A2F7 | 4C8B1 |
| 5F0A9D3C7E8B | F0A9D |
| ZZYYXXWWVVUU | ZYYXX |
| E2B7F5A9C3D0 | 2B7F5 |

## 实现链路

`SUBSTRING`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——标准SUBSTRING(s FROM n FOR m)，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.SUBSTRING`（FlinkSqlOperatorTable.java:750）。
2. **定义**——BuiltInFunctionDefinitions.java:810处的注册条目，注册名`"substring"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经StringCallGen生成对BuiltInMethods/StringUtils的直调，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
