# UUID

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

每次调用生成一个新的RFC 4122 type-4（随机）UUID字符串；非确定。合成键与请求id。

## 用法

输入：`UUID()`——无参数；36字符的STRING。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, UUID() FROM bid;
```

输出：STRING；每行一个新的36字符UUID（非确定）。

示例（输入→输出）：

| 输入 | 输出 |
|---|
| — | 3f8a2c1e-9b4d-4c6a-8e2f-1a5b9d0c7e3a |

输出每行重新生成（非确定），此处展示一次抽取的值。

## 实现链路

`UUID`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——零参函数UUID()，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.UUID`（FlinkSqlOperatorTable.java:742）。
2. **定义**——BuiltInFunctionDefinitions.java:1110处的注册条目，注册名`"uuid"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——标记为非确定，规划期既不折叠也不跨算子移动。
4. **代码生成**——StringCallGen的UUID分支内联java.util.UUID.randomUUID()调用。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
