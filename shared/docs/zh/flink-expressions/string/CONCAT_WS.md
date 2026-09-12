# CONCAT_WS

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

以分隔符连接参数；NULL参数会被跳过而非产生空位，仅分隔符为NULL时才返回NULL。生成a,b,c这类可读列表。

## 用法

输入：`CONCAT_WS(sep, s1, s2, ...)`——sep在前，其后为两个及以上字符串。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CONCAT_WS('-', bid.extra, 'x') FROM bid;
```

输出：STRING；每行为`<extra>-x`。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | CONCAT_WS('-', extra, 'x') |
|---|---|
| A3F19C27B4E0 | A3F19C27B4E0-x |
| 8B2D4F90A1C3 | 8B2D4F90A1C3-x |
| C7E5A0D39F16 | C7E5A0D39F16-x |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5-x |
| D4C8B1E6A2F7 | D4C8B1E6A2F7-x |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B-x |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU-x |
| E2B7F5A9C3D0 | E2B7F5A9C3D0-x |

## 实现链路

`CONCAT_WS`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.CONCAT_WS`（FlinkSqlOperatorTable.java:239）。
2. **定义**——BuiltInFunctionDefinitions.java:939处的注册条目，注册名`"concat_ws"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经StringCallGen生成对BuiltInMethods/StringUtils的直调，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
