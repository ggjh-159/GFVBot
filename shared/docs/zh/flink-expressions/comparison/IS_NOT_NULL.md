# IS_NOT_NULL

分类：[比较函数](../index.md#比较函数) · 别名：—

## 定位与场景

IS NULL的补集，同样绝不返回UNKNOWN。在会对NULL敏感的算术或字符串函数之前先过滤行。

## 用法

签名：`x IS NOT NULL`（后缀谓词形式）

| 参数 | 类型 | 说明 |
|---|---|---|
| x | 任意可空类型 | 待判空的值 |

返回：BOOLEAN；x非NULL得TRUE；结果本身永不为NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction IS NOT NULL) FROM bid;
```

输出：BOOLEAN；本例每行皆为true——`auction`是非空列。

示例（16行源的前8行，示意数据，末行补空值边界；前列为输入列，末两列为该行结果与说明）：

| auction | auction IS NOT NULL | 说明 |
|---|---|---|
| 3 | TRUE | 非NULL值 |
| 19 | TRUE | 非NULL值 |
| 8 | TRUE | 非NULL值 |
| 1 | TRUE | 非NULL值 |
| 14 | TRUE | 非NULL值 |
| 7 | TRUE | 非NULL值 |
| 11 | TRUE | 非NULL值 |
| 20 | TRUE | 非NULL值 |
| NULL | FALSE | 输入为NULL得FALSE，结果永不为NULL |

## 源码位置

GFV实现该表达式的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`IS_NOT_NULL`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`IS_NOT_NULL`条目（SCALAR） |
| 求值逻辑 | 经`ScalarOperatorGens`内联生成 |

## velox实现

velox已有实现：sparksql套件的`isnotnull`（`velox/functions/sparksql/registration/RegisterComparison.cpp`）（prestosql侧仅注册了`is_null`）。
