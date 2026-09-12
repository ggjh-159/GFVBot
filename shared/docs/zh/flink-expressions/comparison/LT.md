# LT

分类：[比较函数](../index.md#比较函数) · 别名：`<`

## 定位与场景

排序谓词：左操作数严格小于右操作数时返回TRUE；任一侧为NULL结果为UNKNOWN。常用于范围过滤、边界检查与两列之间的大小比较。

## 用法

输入：`a < b`——两侧为可比较且可排序的类型（数值、字符串、时间）；NULL得UNKNOWN。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction < bid.bidder FROM bid;
```

输出：BOOLEAN；`auction`小于`bidder`时为true（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | bidder | auction < bidder |
|---|---|---|
| 3 | 15 | TRUE |
| 19 | 7 | FALSE |
| 8 | 8 | FALSE |
| 1 | 42 | TRUE |
| 14 | 23 | TRUE |
| 7 | 2 | FALSE |
| 11 | 11 | FALSE |
| 20 | 36 | TRUE |

## 实现链路

`LT`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——中缀语法，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.LESS_THAN`（FlinkSqlOperatorTable.java:1091）。
2. **定义**——BuiltInFunctionDefinitions.java:483处的注册条目，注册名`"lessThan"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——由ExprCodeGenerator内联为普通Java运算代码（ScalarOperatorGens），无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
