# MAP_VALUES

分类：[集合函数](../index.md#集合函数) · 别名：—

## 定位与场景

按值的迭代顺序返回值数组。展开度量值交给聚合函数。

## 用法

输入：`MAP_VALUES(m)`——m为MAP；返回值类型的ARRAY。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, MAP_VALUES(MAP['k1', 1, 'k2', 2]) FROM bid;
```

输出：ARRAY<INT>；每行均为[1, 2]。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| MAP_VALUES(MAP['k1', 1, 'k2', 2]) | [1, 2] |

## 实现链路

`MAP_VALUES`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，FlinkSqlOperatorTable无专属常量——调用经FunctionDefinitionOperatorTable解析，它把BuiltInFunctionDefinitions条目即时适配为SqlFunction。
2. **定义**——BuiltInFunctionDefinitions.java:156处的注册条目，注册名`"MAP_VALUES"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经BridgingSqlFunctionCallGen调用table-runtime类scalar/MapValuesFunction的eval()（flink-table-runtime，新栈载体）。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
