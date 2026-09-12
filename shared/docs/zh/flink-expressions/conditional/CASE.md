# CASE

分类：[条件函数](../index.md#条件函数) · 别名：—

## 定位与场景

分支选择。搜索形式`CASE WHEN cond THEN val ... [ELSE val] END`自上而下求值，返回首个命中；简单形式`CASE expr WHEN v THEN ... END`按值比较。省略ELSE时默认NULL。逐行打标与NULL安全的if/else逻辑。

## 用法

输入：`CASE WHEN cond THEN v [WHEN ...] [ELSE v] END`——各分支结果须统一类型。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CASE WHEN bid.auction > 10 THEN 'high' ELSE 'low' END FROM bid;
```

输出：STRING；`auction > 10`时为'high'，否则'low'（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | CASE WHEN auction > 10 THEN 'high' ELSE 'low' END |
|---|---|
| 3 | low |
| 19 | high |
| 8 | low |
| 1 | low |
| 14 | high |
| 7 | low |
| 11 | high |
| 20 | high |

## 实现链路

`CASE`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——CASE WHEN..THEN..ELSE..END，FlinkSqlOperatorTable无专属常量——调用经FunctionDefinitionOperatorTable解析，它把BuiltInFunctionDefinitions条目即时适配为SqlFunction。
2. **定义**——BuiltInFunctionDefinitions.java:433处的注册条目，注册名`"ifThenElse"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——由ExprCodeGenerator内联为按条件求值的多分支if/else（ScalarOperatorGens）。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
