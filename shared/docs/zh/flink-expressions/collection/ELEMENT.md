# ELEMENT

分类：[集合函数](../index.md#集合函数) · 别名：—

## 定位与场景

返回单元素数组中唯一的元素；空数组得NULL；多于一个元素则报错。解包已知单值的结果（如子查询输出）。

## 用法

输入：`ELEMENT(arr)`——arr为ARRAY。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ELEMENT(ARRAY[bid.auction]) FROM bid;
```

输出：BIGINT；每行即`auction`的值。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | ELEMENT(ARRAY[auction]) |
|---|---|
| 3 | 3 |
| 19 | 19 |
| 8 | 8 |
| 1 | 1 |
| 14 | 14 |
| 7 | 7 |
| 11 | 11 |
| 20 | 20 |

## 实现链路

`ELEMENT`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.ELEMENT`（FlinkSqlOperatorTable.java:1145）。
2. **定义**——BuiltInFunctionDefinitions.java:1972处的注册条目，注册名`"element"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——由ExprCodeGenerator的ELEMENT分支内联（带基数检查的唯一元素读取）。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
