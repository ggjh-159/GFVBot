# CURRENT_DATABASE

分类：[辅助函数](../index.md#辅助函数) · 别名：—

## 定位与场景

把会话当前数据库名作为STRING返回。模板化SQL与环境感知的路由。

## 用法

输入：`CURRENT_DATABASE()`——无参数；返回STRING。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CURRENT_DATABASE() FROM bid;
```

输出：STRING；每行均为'default_database'。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| — | default_database |

## 实现链路

`CURRENT_DATABASE`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——零参函数，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.CURRENT_DATABASE`（FlinkSqlOperatorTable.java:1283）。
2. **定义**——BuiltInFunctionDefinitions.java:1720处的注册条目，注册名`"currentDatabase"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——StringCallGen的CURRENT_DATABASE分支经addReusableQueryLevelCurrentDatabase内联查询级库名。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
