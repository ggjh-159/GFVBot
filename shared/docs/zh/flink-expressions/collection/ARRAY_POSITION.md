# ARRAY_POSITION

分类：[集合函数](../index.md#集合函数) · 别名：—

## 定位与场景

值首次出现位置的1基下标；不存在为0；数组为NULL得NULL。查找已知元素的位置排名。

## 用法

输入：`ARRAY_POSITION(arr, v)`——arr为ARRAY；返回INT。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_POSITION(ARRAY[1,2,3], 2) FROM bid;
```

输出：INT；每行均为2。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| ARRAY_POSITION(ARRAY[1,2,3], 2) | 2 |

## 实现链路

`ARRAY_POSITION`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，FlinkSqlOperatorTable无专属常量——调用经FunctionDefinitionOperatorTable解析，它把BuiltInFunctionDefinitions条目即时适配为SqlFunction。
2. **定义**——BuiltInFunctionDefinitions.java:247处的注册条目，注册名`"ARRAY_POSITION"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经BridgingSqlFunctionCallGen调用table-runtime类scalar/ArrayPositionFunction的eval()（flink-table-runtime，新栈载体）。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
