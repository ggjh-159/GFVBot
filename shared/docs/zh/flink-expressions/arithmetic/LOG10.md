# LOG10

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

以10为底的对数；非正输入得NULL。分贝类与数量级度量。

## 用法

输入：`LOG10(x)`——DOUBLE；x <= 0返回NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, LOG10(100) FROM bid;
```

输出：DOUBLE；`LOG10(100)`每行均为2.0。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| LOG10(100) | 2.0 |

## 实现链路

`LOG10`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.LOG10`（FlinkSqlOperatorTable.java:1188）。
2. **定义**——BuiltInFunctionDefinitions.java:1435处的注册条目，注册名`"log10"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经MethodCallGen调用FunctionGenerator注册的BuiltInMethods静态方法，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
