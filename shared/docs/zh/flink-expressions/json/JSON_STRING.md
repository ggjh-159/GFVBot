# JSON_STRING

分类：[JSON函数](../index.md#JSON函数) · 别名：—

## 定位与场景

把任意SQL值——包括嵌套row与集合——序列化为JSON文本。JSON构造方向上的通用编码器。

## 用法

输入：`JSON_STRING(v)`——v为任意类型；返回STRING。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_STRING(ROW(1, 'a')) FROM bid;
```

输出：STRING；每行均为'[1,"a"]'——row被序列化为JSON数组。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| JSON_STRING(ROW(1, 'a')) | [1,"a"] |

## 实现链路

`JSON_STRING`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，FlinkSqlOperatorTable无专属常量——调用经FunctionDefinitionOperatorTable解析，它把BuiltInFunctionDefinitions条目即时适配为SqlFunction。
2. **定义**——BuiltInFunctionDefinitions.java:2296处的注册条目，注册名`"JSON_STRING"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——专属JsonStringCallGen——经planner的JSON序列化器序列化值树。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
