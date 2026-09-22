# MAP_ENTRIES

分类：[集合函数](../index.md#集合函数) · 别名：—

## 定位与场景

把map展开为ROW(key, value)对的数组，每个键值对对应结果数组中的一个元素。用于让map接入面向行的API。

## 用法

签名：`MAP_ENTRIES(m)`

| 参数 | 类型 | 说明 |
|---|---|---|
| m | MAP<K, V> | 待展开的map |

返回：ARRAY<ROW<K, V>>；每个键值对展开为一个ROW(key, value)。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, MAP_ENTRIES(MAP['k1', 1]) FROM bid;
```

输出：ARRAY<ROW<STRING, INT>>；每次调用得到一行(k1, 1)。

| 输入 | 输出 | 说明 |
|---|---|---|
| MAP_ENTRIES(MAP['k1', 1]) | [(k1, 1)] | 键值对(k1, 1)展开为一个ROW |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`MAP_ENTRIES`条目（SCALAR） |
| 求值逻辑 | `MapEntriesFunction`的`eval()`（flink-table-runtime，经`BridgingSqlFunctionCallGen`调用） |

## velox实现

velox已有内建`map_entries`（`velox/functions/prestosql/registration/MapFunctionsRegistration.cpp`）。
