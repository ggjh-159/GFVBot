# ASIN

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

反正弦（弧度）；输入超出[-1, 1]得NULL。对正弦类特征求逆。

## 用法

输入：`ASIN(x)`——DOUBLE；|x| > 1返回NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ASIN(0.5) FROM bid;
```

输出：DOUBLE；`ASIN(0.5)`每行均为0.5235987755982989。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| ASIN(0.5) | 0.5235987755982989 |

## 实现链路

`ASIN`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.ASIN`（FlinkSqlOperatorTable.java:1201）。
2. **定义**——BuiltInFunctionDefinitions.java:1565处的注册条目，注册名`"asin"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经MethodCallGen调用FunctionGenerator注册的BuiltInMethods静态方法，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
