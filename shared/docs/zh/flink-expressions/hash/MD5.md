# MD5

分类：[哈希函数](../index.md#哈希函数) · 别名：—

## 定位与场景

字符串的128位MD5摘要，渲染为32个小写十六进制字符。变更检测、缓存键、指纹——其抗碰撞性不足以用于安全场景。

## 用法

输入：`MD5(s)`——s为STRING；返回32字符的STRING。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, MD5(bid.extra) FROM bid;
```

输出：STRING；每行32个十六进制字符（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | MD5(extra) |
|---|---|
| A3F19C27B4E0 | 3391d976e274ac3c8b3987f29f4cfd90 |
| 8B2D4F90A1C3 | d2700e68ec3f4bf6ab516f28083fb04a |
| C7E5A0D39F16 | ffd94a91f55bebe588985be25c3d3edd |
| ZK9M2Q7XVBT5 | acba1453a0ecdcdeb60e6cd1ddd0f70d |
| D4C8B1E6A2F7 | 05c4ad9174cc98f55266ab0883c337b1 |
| 5F0A9D3C7E8B | 7aa3ea2eba7a655fea2c8e2610af726e |
| ZZYYXXWWVVUU | 83fd3f4384f97d588a344e76e0940f03 |
| E2B7F5A9C3D0 | af8edb2fd39e82bc68428cb9d71ef95f |

## 实现链路

`MD5`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.MD5`（FlinkSqlOperatorTable.java:511）。
2. **定义**——BuiltInFunctionDefinitions.java:2052处的注册条目，注册名`"md5"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经StringCallGen生成对BuiltInMethods/StringUtils的直调，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
