# E

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

欧拉数e，DOUBLE类型。零参数但需带括号写作`E()`。

## 用法

输入：`E()`——无参数；DOUBLE。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, E() FROM bid;
```

输出：DOUBLE；每行均为2.718281828459045。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| — | 2.718281828459045 |

## 实现链路

`E`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——零参函数E()，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.E`（FlinkSqlOperatorTable.java:210）。
2. **定义**——BuiltInFunctionDefinitions.java:1653处的注册条目，注册名`"e"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——ConstantCallGen把Math.E常量直接内联进生成代码。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
