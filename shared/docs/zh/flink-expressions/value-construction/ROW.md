# ROW

分类：[值构造函数](../index.md#值构造函数) · 别名：—

## 定位与场景

行构造器`ROW(v1, v2, ...)`生成匿名的复合值，字段名为f0、f1等（可用AS重命名）。把一同流转的异构值打包。

## 用法

输入：`ROW(v1, v2, ...)`——各字段类型可不同。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ROW(1, 'a', bid.auction) FROM bid;
```

输出：ROW<INT, STRING, BIGINT>；每行为`(1, 'a', auction)`。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | ROW(1, 'a', auction) |
|---|---|
| 3 | (1, a, 3) |
| 19 | (1, a, 19) |
| 8 | (1, a, 8) |
| 1 | (1, a, 1) |
| 14 | (1, a, 14) |
| 7 | (1, a, 7) |
| 11 | (1, a, 11) |
| 20 | (1, a, 20) |

## 实现链路

`ROW`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——ROW(..)构造器，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.ROW`（FlinkSqlOperatorTable.java:1156）。
2. **定义**——BuiltInFunctionDefinitions.java:1989处的注册条目，注册名`"row"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——由ExprCodeGenerator的ROW分支内联为GenericRowData构造。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
