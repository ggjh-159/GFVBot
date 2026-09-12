# TRY_CAST

分类：[类型转换函数](../index.md#类型转换函数) · 别名：—

## 定位与场景

与CAST相同的转换矩阵，但转换失败得NULL而非报错。清洗脏列而不让作业挂掉。

## 用法

输入：`TRY_CAST(x AS t)`——t为具体SQL类型；失败得NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, TRY_CAST('bid.extra' AS INT) FROM bid;
```

输出：INT；每行均为NULL——字面量'bid.extra'不是合法整数。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| TRY_CAST('bid.extra' AS INT) | NULL |

## 实现链路

`TRY_CAST`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——TRY_CAST(x AS t)，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.TRY_CAST`（FlinkSqlOperatorTable.java:938）。
2. **定义**——BuiltInFunctionDefinitions.java:2400处的注册条目，注册名`"TRY_CAST"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——与CAST同一codegen路径，外加失败得NULL的包装。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
