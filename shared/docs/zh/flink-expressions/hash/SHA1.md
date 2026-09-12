# SHA1

分类：[哈希函数](../index.md#哈希函数) · 别名：—

## 定位与场景

160位SHA-1摘要，40个小写十六进制字符。传统指纹用途——安全相关场景请改用SHA-2系列。

## 用法

输入：`SHA1(s)`——s为STRING；返回40字符的STRING。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, SHA1(bid.extra) FROM bid;
```

输出：STRING；每行40个十六进制字符（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | SHA1(extra) |
|---|---|
| A3F19C27B4E0 | 44efb9590ae04716b158b17ebdaf9e6bfa5c5dab |
| 8B2D4F90A1C3 | 3fde48eac4ceff69c20a7c0daa0467e1eba4ad1f |
| C7E5A0D39F16 | ae380e5be7cdd061963e6791bfa6968732657283 |
| ZK9M2Q7XVBT5 | c725c42b953ede1222cf7090f2f8bf1676e08fe4 |
| D4C8B1E6A2F7 | 12e227e4a5a9248aa8a94cbc89efa07e7f2e1ab2 |
| 5F0A9D3C7E8B | 7ca21ce9fbfd9c1b6e46f245b1f3541b8aa66180 |
| ZZYYXXWWVVUU | 503c53179981a96e0fa7a9c21bb00c9169fdea35 |
| E2B7F5A9C3D0 | 27d75fb52e892e24ee936a61ce4fee4bf5e17491 |

## 实现链路

`SHA1`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.SHA1`（FlinkSqlOperatorTable.java:522）。
2. **定义**——BuiltInFunctionDefinitions.java:2060处的注册条目，注册名`"sha1"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经StringCallGen生成对BuiltInMethods/StringUtils的直调，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
