# JSON_EXISTS

分类：[JSON函数](../index.md#JSON函数) · 别名：—

## 定位与场景

SQL/JSON路径在文档中定位到至少一个值时返回TRUE。对JSON载荷做快速存在性判断。

## 用法

输入：`JSON_EXISTS(json, path)`——json为STRING，path为SQL/JSON路径。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_EXISTS('{"a": 1}', '$.a') FROM bid;
```

输出：BOOLEAN；每行均为true——路径$.a存在。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| JSON_EXISTS('{"a": 1}', '$.a') | TRUE |

## 实现链路

`JSON_EXISTS`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.JSON_EXISTS`（FlinkSqlOperatorTable.java:1246）。
2. **定义**——BuiltInFunctionDefinitions.java:2240处的注册条目，注册名`"JSON_EXISTS"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经MethodCallGen调用FunctionGenerator注册的BuiltInMethods静态方法，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
