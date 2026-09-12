# LOWER

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

把字符串转为小写。JOIN或去重前对标识符与键做规范化。

## 用法

输入：`LOWER(s)`——s为STRING/CHAR；NULL得NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, LOWER(bid.extra) FROM bid;
```

输出：STRING；每行`extra`的12个字符转为小写（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | LOWER(extra) |
|---|---|
| A3F19C27B4E0 | a3f19c27b4e0 |
| 8B2D4F90A1C3 | 8b2d4f90a1c3 |
| C7E5A0D39F16 | c7e5a0d39f16 |
| ZK9M2Q7XVBT5 | zk9m2q7xvbt5 |
| D4C8B1E6A2F7 | d4c8b1e6a2f7 |
| 5F0A9D3C7E8B | 5f0a9d3c7e8b |
| ZZYYXXWWVVUU | zzyyxxwwvvuu |
| E2B7F5A9C3D0 | e2b7f5a9c3d0 |

## 实现链路

`LOWER`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.LOWER`（FlinkSqlOperatorTable.java:1182）。
2. **定义**——BuiltInFunctionDefinitions.java:780处的注册条目，注册名`"lower"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经StringCallGen生成对BuiltInMethods/StringUtils的直调，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
