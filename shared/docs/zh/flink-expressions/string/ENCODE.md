# ENCODE

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

按指定字符集把字符串s编码为字节，返回VARBINARY。为字节级函数准备输入。

## 用法

输入：`ENCODE(s, charset)`——charset如'utf-8'；返回VARBINARY。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ENCODE(bid.extra, 'utf-8') FROM bid;
```

输出：VARBINARY；每行`extra`的12个UTF-8字节。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | ENCODE(extra, 'utf-8') |
|---|---|
| A3F19C27B4E0 | 413346313943323742344530 |
| 8B2D4F90A1C3 | 384232443446393041314333 |
| C7E5A0D39F16 | 433745354130443339463136 |
| ZK9M2Q7XVBT5 | 5A4B394D3251375856425435 |
| D4C8B1E6A2F7 | 443443384231453641324637 |
| 5F0A9D3C7E8B | 354630413944334337453842 |
| ZZYYXXWWVVUU | 5A5A59595858575756565555 |
| E2B7F5A9C3D0 | 453242374635413943334430 |

## 实现链路

`ENCODE`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——函数形式，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.ENCODE`（FlinkSqlOperatorTable.java:871）。
2. **定义**——BuiltInFunctionDefinitions.java:1034处的注册条目，注册名`"encode"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经StringCallGen生成对BuiltInMethods/StringUtils的直调，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
