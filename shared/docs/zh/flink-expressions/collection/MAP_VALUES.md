# MAP_VALUES

分类：[集合函数](../index.md#集合函数) · 别名：—

## 定位与场景

按map值的迭代顺序返回全部值组成的数组。用于把度量值展开交给聚合函数。

## 用法

签名：`MAP_VALUES(m)`

| 参数 | 类型 | 说明 |
|---|---|---|
| m | MAP<K, V> | 待取值的map |

返回：ARRAY<V>；按值的迭代顺序排列。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, MAP_VALUES(MAP['k1', 1, 'k2', 2]) FROM bid;
```

输出：ARRAY<INT>；每行均为[1, 2]。

| 输入 | 输出 | 说明 |
|---|---|---|
| MAP_VALUES(MAP['k1', 1, 'k2', 2]) | [1, 2] | 按值的迭代顺序返回 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`MAP_VALUES`条目（SCALAR） |
| 求值逻辑 | `MapValuesFunction`的`eval()`（flink-table-runtime，经`BridgingSqlFunctionCallGen`调用） |

## velox实现

velox已有内建`map_values`（`velox/functions/prestosql/registration/MapFunctionsRegistration.cpp`）。
