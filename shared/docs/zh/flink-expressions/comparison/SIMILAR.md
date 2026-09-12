# SIMILAR

分类：[比较函数](../index.md#比较函数) · 别名：`SIMILAR TO`

## 定位与场景

经`s SIMILAR TO pattern`按SQL:1999正则匹配——其语法（字符类、基于%和_的量词）既不同于LIKE通配符也不同于Java正则。

## 用法

输入：`s SIMILAR TO pattern`——均为字符串；返回BOOLEAN。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.extra SIMILAR TO '%[0-9A-F]%' FROM bid;
```

输出：BOOLEAN；`extra`至少含一个0-9A-F字符时为true（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | extra SIMILAR TO '%[0-9A-F]%' |
|---|---|
| A3F19C27B4E0 | TRUE |
| 8B2D4F90A1C3 | TRUE |
| C7E5A0D39F16 | TRUE |
| ZK9M2Q7XVBT5 | TRUE |
| D4C8B1E6A2F7 | TRUE |
| 5F0A9D3C7E8B | TRUE |
| ZZYYXXWWVVUU | FALSE |
| E2B7F5A9C3D0 | TRUE |

## 实现链路

`SIMILAR`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——中缀s SIMILAR TO pattern，FlinkSqlOperatorTable无专属常量——调用经FunctionDefinitionOperatorTable解析，它把BuiltInFunctionDefinitions条目即时适配为SqlFunction。
2. **定义**——BuiltInFunctionDefinitions.java:798处的注册条目，注册名`"similar"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经StringCallGen生成对BuiltInMethods/StringUtils的直调，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
