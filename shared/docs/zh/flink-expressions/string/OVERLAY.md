# OVERLAY

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

把s中从1基位置n起、长m个字符的子串替换为r：`OVERLAY(s PLACING r FROM n FOR m)`。定宽段的原位修补。

## 用法

输入：`OVERLAY(s PLACING r FROM n [FOR m])`——n、m为INT。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, OVERLAY(bid.extra PLACING '**' FROM 2 FOR 2) FROM bid;
```

输出：STRING；`extra`第2到3个字符替换为'**'——每行仍是12个字符。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | OVERLAY(extra PLACING '**' FROM 2 FOR 2) |
|---|---|
| A3F19C27B4E0 | A**9C27B4E0 |
| 8B2D4F90A1C3 | 8**4F90A1C3 |
| C7E5A0D39F16 | C**A0D39F16 |
| ZK9M2Q7XVBT5 | Z**2Q7XVBT5 |
| D4C8B1E6A2F7 | D**B1E6A2F7 |
| 5F0A9D3C7E8B | 5**9D3C7E8B |
| ZZYYXXWWVVUU | Z**XXWWVVUU |
| E2B7F5A9C3D0 | E**F5A9C3D0 |

## 实现链路

`OVERLAY`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——标准OVERLAY(s PLACING r FROM n FOR m)，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.OVERLAY`（FlinkSqlOperatorTable.java:1176）。
2. **定义**——BuiltInFunctionDefinitions.java:905处的注册条目，注册名`"overlay"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经StringCallGen生成对BuiltInMethods/StringUtils的直调，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
