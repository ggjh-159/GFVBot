# AT

分类：[集合函数](../index.md#集合函数) · 别名：`[]`, ITEM

## 定位与场景

用[]运算符取元素：`arr[i]`读数组第i个元素（1基），`map[k]`按键查值。内部注册名为ITEM——报错信息里显示的就是这个名字。

## 用法

输入：`arr[i]`/`map[k]`——数组下标1基；键为map键类型。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY[bid.auction, bid.bidder, 99][3] FROM bid;
```

输出：BIGINT；每行均为99——字面量数组的第三个元素。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | bidder | ARRAY[auction, bidder, 99][3] |
|---|---|---|
| 3 | 15 | 99 |
| 19 | 7 | 99 |
| 8 | 8 | 99 |
| 1 | 42 | 99 |
| 14 | 23 | 99 |
| 7 | 2 | 99 |
| 11 | 11 | 99 |
| 20 | 36 | 99 |

## 实现链路

`AT`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——下标访问arr[i] / map[k]，FlinkSqlOperatorTable无专属常量——调用经FunctionDefinitionOperatorTable解析，它把BuiltInFunctionDefinitions条目即时适配为SqlFunction。
2. **定义**——BuiltInFunctionDefinitions.java:1932处的注册条目，注册名`"at"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——由ExprCodeGenerator的ITEM分支内联（对内部数据结构做数组下标/map查找）。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
