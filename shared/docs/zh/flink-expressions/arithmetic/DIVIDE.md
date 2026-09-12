# DIVIDE

分类：[算术函数](../index.md#算术函数) · 别名：`/`

## 定位与场景

数值除法。整数除整数返回DOUBLE——Flink不做截断的整数除法；DECIMAL/DECIMAL返回按精度推导的DECIMAL。NULL传播。用于比率与单位度量。

## 用法

输入：`a / b`——数值除以数值；整型输入得DOUBLE，DECIMAL输入得DECIMAL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction / 7 FROM bid;
```

输出：DOUBLE；每行的`auction / 7`，如3 / 7 = 0.42857142857142855。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | auction / 7 |
|---|---|
| 3 | 0.42857142857142855 |
| 19 | 2.7142857142857144 |
| 8 | 1.1428571428571428 |
| 1 | 0.14285714285714285 |
| 14 | 2.0 |
| 7 | 1.0 |
| 11 | 1.5714285714285714 |
| 20 | 2.857142857142857 |

## 实现链路

`DIVIDE`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——中缀语法，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.DIVIDE`（FlinkSqlOperatorTable.java:1082）。
2. **定义**——BuiltInFunctionDefinitions.java:1337处的注册条目，注册名`"divide"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——内联算术（ScalarOperatorGens）；DECIMAL除法走DivCallGen的保精度路径。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
