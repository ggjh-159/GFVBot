# TRIM

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

去掉首和/或尾部的字符；默认去掉两端空格（BOTH）。LEADING/TRAILING选定一侧，也可指定要去除的字符而非空格。

## 用法

输入：`TRIM([BOTH|LEADING|TRAILING] [c] FROM s)`——默认两端空格。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, TRIM(BOTH ' ' FROM CONCAT(' ', bid.extra, ' ')) FROM bid;
```

输出：STRING；去掉人为加的空格后——每行即`extra`本身。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | TRIM(BOTH ' ' FROM CONCAT(' ', extra, ' ')) |
|---|---|
| A3F19C27B4E0 | A3F19C27B4E0 |
| 8B2D4F90A1C3 | 8B2D4F90A1C3 |
| C7E5A0D39F16 | C7E5A0D39F16 |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5 |
| D4C8B1E6A2F7 | D4C8B1E6A2F7 |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU |
| E2B7F5A9C3D0 | E2B7F5A9C3D0 |

## 实现链路

`TRIM`从SQL文本到执行算子的路径（Flink 1.19.2）：

1. **解析**——TRIM([BOTH|LEADING|TRAILING] c FROM s)，解析器产出SqlNode，算子锚点为`FlinkSqlOperatorTable.TRIM`（FlinkSqlOperatorTable.java:1177）。
2. **定义**——BuiltInFunctionDefinitions.java:856处的注册条目，注册名`"trim"`，kind为SCALAR；planner把解析出的调用绑定到该定义。
3. **规划**——无专属改写；作为普通RexCall随通用规则移动——过滤/投影下推、CalcMergeRule，全字面量时被常量折叠（ExpressionReducer）。
4. **代码生成**——经StringCallGen生成对BuiltInMethods/StringUtils的直调，无独立运行时类。
5. **执行**——经Janino编译进消费ExecNode的算子：投影/过滤时就是StreamExecCalc生成的TableStreamOperator子类（CodeGenOperatorFactory），在processElement里逐行求值；出现在JOIN条件或聚合参数中时改在StreamExecJoin / StreamExecGroupAggregate的算子里执行。见[链路总览](../index.md#链路总览)。
