# CHAR_LENGTH

分类：[字符串函数](../index.md#字符串函数) · 别名：`CHARACTER_LENGTH`

## 定位与场景

字符串的字符数（不是字节数）。长度校验、截断逻辑与宽度检查。

## 用法

输入：`CHAR_LENGTH(s)`——s为STRING/CHAR；返回INT。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CHAR_LENGTH(bid.extra) FROM bid;
```

输出：INT；每行均为12（`extra`生成长度为12）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | CHAR_LENGTH(extra) |
|---|---|
| A3F19C27B4E0 | 12 |
| 8B2D4F90A1C3 | 12 |
| C7E5A0D39F16 | 12 |
| ZK9M2Q7XVBT5 | 12 |
| D4C8B1E6A2F7 | 12 |
| 5F0A9D3C7E8B | 12 |
| ZZYYXXWWVVUU | 12 |
| E2B7F5A9C3D0 | 12 |

## 实现链路

`CHAR_LENGTH`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.CHAR_LENGTH`（FlinkSqlOperatorTable.java:1179）。
2. **定义**——BuiltInFunctionDefinitions.java:752处的注册条目，注册名`"charLength"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经StringCallGen生成对BuiltInMethods/StringUtils的直调，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
