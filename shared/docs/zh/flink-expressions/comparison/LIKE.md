# LIKE

分类：[比较函数](../index.md#比较函数) · 别名：—

## 定位与场景

SQL通配匹配：`%`匹配任意字符序列，`_`恰好一个字符；ESCAPE指定转义字符。区分大小写。按形态过滤名称与id。

## 用法

输入：`s LIKE pattern [ESCAPE c]`——均为字符串；返回BOOLEAN。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.extra LIKE '%A%' FROM bid;
```

输出：BOOLEAN；`extra`包含'A'时为true（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | extra LIKE '%A%' |
|---|---|
| A3F19C27B4E0 | TRUE |
| 8B2D4F90A1C3 | TRUE |
| C7E5A0D39F16 | TRUE |
| ZK9M2Q7XVBT5 | FALSE |
| D4C8B1E6A2F7 | TRUE |
| 5F0A9D3C7E8B | TRUE |
| ZZYYXXWWVVUU | FALSE |
| E2B7F5A9C3D0 | TRUE |

## 实现链路

`LIKE`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——中缀s LIKE pattern [ESCAPE c]，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.LIKE`（FlinkSqlOperatorTable.java:1165）。
2. **定义**——BuiltInFunctionDefinitions.java:768处的注册条目，注册名`"like"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——StringCallGen把LIKE转交LikeCallGen（编译好的模式作为算子可复用成员缓存）。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
