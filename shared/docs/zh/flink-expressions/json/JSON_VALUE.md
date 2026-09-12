# JSON_VALUE

分类：[JSON函数](../index.md#JSON函数) · 别名：—

## 定位与场景

抽取SQL/JSON路径处的标量并按字符串（或RETURNING类型）返回；ON EMPTY/ON ERROR子句决定路径缺失或类型不匹配时的行为。

## 用法

输入：`JSON_VALUE(json, path [RETURNING t] [on empty/error])`——json为STRING。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_VALUE('{"a": 1}', '$.a') FROM bid;
```

输出：STRING；每行均为'1'——数值标量按文本渲染。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| JSON_VALUE('{"a": 1}', '$.a') | 1 |

## 实现链路

`JSON_VALUE`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.JSON_VALUE`（FlinkSqlOperatorTable.java:1247）。
2. **定义**——BuiltInFunctionDefinitions.java:2262处的注册条目，注册名`"JSON_VALUE"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——专属JsonValueCallGen（planner的codegen/calls），处理ON EMPTY/ON ERROR。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
