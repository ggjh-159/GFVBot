# NOT_BETWEEN

分类：[比较函数](../index.md#比较函数) · 别名：—

## 定位与场景

`x NOT BETWEEN lo AND hi`是BETWEEN的否定：x在闭区间之外时为TRUE；任一操作数为NULL时仍得UNKNOWN，并非对BETWEEN简单取反。用于排除某一段取值。

## 用法

签名：`x NOT BETWEEN lo AND hi`——各部分含义同BETWEEN：x为被检表达式，lo、hi为同一可比较类型的下界与上界。

返回：BOOLEAN；x在闭区间`[lo, hi]`之外为TRUE；任一操作数为NULL时结果为UNKNOWN。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.price NOT BETWEEN 10.00 AND 60.00 FROM bid;
```

输出：BOOLEAN；`price`低于10.00或高于60.00时为true（随行数据变化）。

示例（16行源的前8行，示意数据，末行补空值边界；前列为输入列，末两列为该行结果与说明）：

| price | price NOT BETWEEN 10.00 AND 60.00 | 说明 |
|---|---|---|
| 55.67 | FALSE | 落在闭区间内 |
| 12.50 | FALSE | 落在闭区间内 |
| 99.99 | TRUE | 高于上界 |
| 3.14 | TRUE | 低于下界 |
| 61.20 | TRUE | 高于上界 |
| 28.05 | FALSE | 落在闭区间内 |
| 77.77 | TRUE | 高于上界 |
| 45.00 | FALSE | 落在闭区间内 |
| NULL | UNKNOWN | 输入为NULL仍得UNKNOWN，非TRUE |

## 源码位置

GFV实现该表达式的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`NOT_BETWEEN`条目；Sql到Rex转换阶段被改写为SEARCH RexCall（SARG范围） |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`NOT_BETWEEN`条目（SCALAR） |
| 求值逻辑 | 改写为SEARCH后由`SearchOperatorGen`展开为区间比较 |

## velox实现

velox已有内建`between`（`velox/functions/prestosql/registration/ComparisonFunctionsRegistration.cpp`）（取反需在表达式层完成）。
