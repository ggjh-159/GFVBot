# POSITION

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

x在s中首次出现的位置（1基）；不存在为0；任一输入为NULL得NULL。标准SQL写法是`POSITION(x IN s)`。

## 用法

输入：`POSITION(x IN s)`——参数为字符串；返回INT。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, POSITION('A' IN bid.extra) FROM bid;
```

输出：INT；`extra`中首个'A'的下标，不存在则为0（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | POSITION('A' IN extra) |
|---|---|
| A3F19C27B4E0 | 1 |
| 8B2D4F90A1C3 | 9 |
| C7E5A0D39F16 | 5 |
| ZK9M2Q7XVBT5 | 0 |
| D4C8B1E6A2F7 | 9 |
| 5F0A9D3C7E8B | 4 |
| ZZYYXXWWVVUU | 0 |
| E2B7F5A9C3D0 | 7 |

## 实现链路

`POSITION`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——标准POSITION(x IN s)，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.POSITION`（FlinkSqlOperatorTable.java:1178）。
2. **定义**——BuiltInFunctionDefinitions.java:888处的注册条目，注册名`"position"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经StringCallGen生成对BuiltInMethods/StringUtils的直调，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
