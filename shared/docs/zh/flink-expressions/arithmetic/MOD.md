# MOD

分类：[算术函数](../index.md#算术函数) · 别名：`%`

## 定位与场景

整数除法的余数；符号与被除数一致。常用于分桶（如`MOD(id, n)`做分片或采样）、周期循环与奇偶判断。

## 用法

输入：`MOD(a, b)`或`a % b`——整型（或DECIMAL）操作数；除零会报错。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, MOD(bid.auction, 7) FROM bid;
```

输出：BIGINT；`auction / 7`的余数，每行0-6（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | MOD(auction, 7) |
|---|---|
| 3 | 3 |
| 19 | 5 |
| 8 | 1 |
| 1 | 1 |
| 14 | 0 |
| 7 | 0 |
| 11 | 4 |
| 20 | 6 |

## 实现链路

`MOD`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式或中缀%，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.MOD`（FlinkSqlOperatorTable.java:1186）。
2. **定义**——BuiltInFunctionDefinitions.java:1483处的注册条目，注册名`"mod"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——由ExprCodeGenerator内联为普通Java运算代码（ScalarOperatorGens），无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
