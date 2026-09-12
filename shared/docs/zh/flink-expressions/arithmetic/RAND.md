# RAND

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回[0, 1)上均匀分布的DOUBLE；不带seed时每行非确定，带seed则序列可复现。抽样、负载打散、合成列。

## 用法

输入：`RAND()`或`RAND(seed)`——可选BIGINT种子。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, RAND() FROM bid;
```

输出：[0.0, 1.0)内的DOUBLE；每行重新抽取（非确定）。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| — | 0.5310239745577783 |

输出每行重新生成（非确定），此处展示一次抽取的值。

## 实现链路

`RAND`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——零参或带seed的函数，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.RAND`（FlinkSqlOperatorTable.java:940）。
2. **定义**——BuiltInFunctionDefinitions.java:1661处的注册条目，注册名`"rand"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——标记为非确定，规划期既不折叠也不跨算子移动。
4. **代码生成**——RandCallGen——在算子内生成Random成员（带seed可复现）。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
