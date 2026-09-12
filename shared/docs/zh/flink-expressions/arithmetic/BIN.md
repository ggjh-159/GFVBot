# BIN

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

整数的二进制（base-2）文本。检查标志位与id的位级形态。

## 用法

输入：`BIN(n)`——n为整数；返回STRING。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, BIN(bid.auction) FROM bid;
```

输出：STRING；`auction`的二进制数字（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | BIN(auction) |
|---|---|
| 3 | 11 |
| 19 | 10011 |
| 8 | 1000 |
| 1 | 1 |
| 14 | 1110 |
| 7 | 111 |
| 11 | 1011 |
| 20 | 10100 |

## 实现链路

`BIN`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.BIN`（FlinkSqlOperatorTable.java:288）。
2. **定义**——BuiltInFunctionDefinitions.java:1684处的注册条目，注册名`"bin"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经StringCallGen生成对BuiltInMethods/StringUtils的直调，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
