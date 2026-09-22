# CARDINALITY

分类：[集合函数](../index.md#集合函数) · 别名：—

## 定位与场景

返回数组元素的个数或map键值对的个数；输入为NULL得NULL。用于长度保护条件与按元素个数组织循环的判断。

## 用法

签名：`CARDINALITY(arr_or_map)`

| 参数 | 类型 | 说明 |
|---|---|---|
| arr_or_map | ARRAY<T>或MAP<K, V> | 待计数的数组或map |

返回：INT；数组元素个数或map键值对个数。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CARDINALITY(ARRAY[bid.auction, bid.bidder]) FROM bid;
```

输出：INT；每行均为2。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | bidder | CARDINALITY(ARRAY[auction, bidder]) |
|---|---|---|
| 3 | 15 | 2 |
| 19 | 7 | 2 |
| 8 | 8 | 2 |
| 1 | 42 | 2 |
| 14 | 23 | 2 |
| 7 | 2 | 2 |
| 11 | 11 | 2 |
| 20 | 36 | 2 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`CARDINALITY`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`CARDINALITY`条目（SCALAR） |
| 求值逻辑 | 经`ExprCodeGenerator`的CARDINALITY分支内联生成（读数组/map大小） |

## velox实现

velox已有内建`cardinality`（`velox/functions/prestosql/registration/GeneralFunctionsRegistration.cpp`）。
