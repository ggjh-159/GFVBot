# UNIX_TIMESTAMP

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

把时间字符串（可选格式）转换为会话时区下的epoch秒；无参时返回当前epoch秒。与unix风格API互通。

## 用法

输入：`UNIX_TIMESTAMP([s[, format]])`——s为STRING；返回BIGINT。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, UNIX_TIMESTAMP('2026-09-11 10:00:00') FROM bid;
```

输出：BIGINT；按会话时区读取'2026-09-11 10:00:00'的epoch秒——UTC+8下为1789092000。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| UNIX_TIMESTAMP('2026-09-11 10:00:00') | 1789092000 |
注：此处按UTC+8会话时区读取。

## 实现链路

`UNIX_TIMESTAMP`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——零参或字符串形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.UNIX_TIMESTAMP`（FlinkSqlOperatorTable.java:645）。
2. **定义**——BuiltInFunctionDefinitions.java:1877处的注册条目，注册名`"unixTimestamp"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——零参形式是查询级常量；字符串形式是普通逐行表达式。
4. **代码生成**——经MethodCallGen调用FunctionGenerator注册的BuiltInMethods静态方法，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
