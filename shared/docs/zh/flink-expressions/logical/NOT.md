# NOT

分类：[逻辑函数](../index.md#逻辑函数) · 别名：—

## 定位与场景

逻辑否定：TRUE变FALSE、FALSE变TRUE；UNKNOWN仍为UNKNOWN。操作数要加括号——优先级问题是NOT的经典坑。

## 用法

输入：`NOT a`——操作数为BOOLEAN；NULL仍为NULL（unknown）。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, NOT (bid.auction > 5) FROM bid;
```

输出：BOOLEAN；每行对`auction > 5`取反（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | NOT (auction > 5) |
|---|---|
| 3 | TRUE |
| 19 | FALSE |
| 8 | FALSE |
| 1 | TRUE |
| 14 | FALSE |
| 7 | FALSE |
| 11 | FALSE |
| 20 | FALSE |

## 实现链路

`NOT`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——前缀NOT，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.NOT`（FlinkSqlOperatorTable.java:1116）。
2. **定义**——BuiltInFunctionDefinitions.java:424处的注册条目，注册名`"not"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——由ExprCodeGenerator内联为普通Java运算代码（ScalarOperatorGens），无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
