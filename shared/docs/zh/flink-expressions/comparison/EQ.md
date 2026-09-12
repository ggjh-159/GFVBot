# EQ

分类：[比较函数](../index.md#比较函数) · 别名：`=`

## 定位与场景

比较两个操作数是否相等，相等返回TRUE；任一侧为NULL时结果为UNKNOWN（WHERE中按不满足处理）。SQL里最基础的谓词，广泛用于等值过滤、JOIN条件与CASE分支。

## 用法

输入：`a = b`——两侧为可互相比较的类型（数值、字符串、布尔、时间）；任一侧为NULL则结果为UNKNOWN。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction = bid.bidder FROM bid;
```

输出：BOOLEAN；每行一个值，`auction`与`bidder`相等时为true（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | bidder | auction = bidder |
|---|---|---|
| 3 | 15 | FALSE |
| 19 | 7 | FALSE |
| 8 | 8 | TRUE |
| 1 | 42 | FALSE |
| 14 | 23 | FALSE |
| 7 | 2 | FALSE |
| 11 | 11 | TRUE |
| 20 | 36 | FALSE |

## 实现链路

`EQ`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——中缀语法，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.EQUALS`（FlinkSqlOperatorTable.java:1085）。
2. **定义**——BuiltInFunctionDefinitions.java:456处的注册条目，注册名`"equals"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——由ExprCodeGenerator内联为普通Java运算代码（ScalarOperatorGens），无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
