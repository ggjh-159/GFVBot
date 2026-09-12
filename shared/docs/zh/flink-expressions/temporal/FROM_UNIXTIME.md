# FROM_UNIXTIME

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

把epoch秒（BIGINT）格式化为会话时区下的时间字符串，可选格式模式。把epoch列渲染成可读形式。

## 用法

输入：`FROM_UNIXTIME(unixtime[, format])`——unixtime为BIGINT；返回STRING。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, FROM_UNIXTIME(1760000000) FROM bid;
```

输出：STRING；1760000000在UTC下渲染为'2025-10-09 12:26:40'——文本随会话时区变化（Asia/Shanghai为'2025-10-09 20:26:40'）。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| FROM_UNIXTIME(1760000000) | 2025-10-09 12:26:40 |
注：此处按UTC会话时区渲染。

## 实现链路

`FROM_UNIXTIME`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.FROM_UNIXTIME`（FlinkSqlOperatorTable.java:666）。
2. **定义**——BuiltInFunctionDefinitions.java:1864处的注册条目，注册名`"fromUnixtime"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经MethodCallGen调用FunctionGenerator注册的BuiltInMethods静态方法，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
