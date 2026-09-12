# IFNULL

分类：[条件函数](../index.md#条件函数) · 别名：—

## 定位与场景

两参数版的COALESCE：`IFNULL(a, b)`在a非NULL时取a，否则取b。单列可空值的简洁兜底写法。

## 用法

输入：`IFNULL(a, b)`——a、b为可统一类型。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, IFNULL(CAST(NULL AS STRING), bid.extra) FROM bid;
```

输出：STRING；即`extra`本身——第一个参数为NULL，取到第二个。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | IFNULL(NULL, extra) |
|---|---|
| A3F19C27B4E0 | A3F19C27B4E0 |
| 8B2D4F90A1C3 | 8B2D4F90A1C3 |
| C7E5A0D39F16 | C7E5A0D39F16 |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5 |
| D4C8B1E6A2F7 | D4C8B1E6A2F7 |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU |
| E2B7F5A9C3D0 | E2B7F5A9C3D0 |

## 实现链路

`IFNULL`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，FlinkSqlOperatorTable无专属常量——调用经FunctionDefinitionOperatorTable解析，它把BuiltInFunctionDefinitions条目即时适配为SqlFunction。
2. **定义**——BuiltInFunctionDefinitions.java:132处的注册条目，注册名`"IFNULL"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经BridgingSqlFunctionCallGen调用table-runtime类scalar/IfNullFunction的eval()（flink-table-runtime，新栈载体）。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
