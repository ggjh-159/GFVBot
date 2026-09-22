# MAP_FROM_ARRAYS

分类：[集合函数](../index.md#集合函数) · 别名：—

## 定位与场景

由键数组与值数组（先键后值）构造MAP，两数组须等长，键值按位置配对。是MAP_KEYS/MAP_VALUES的逆方向，用于把并列的列组装成map。

## 用法

签名：`MAP_FROM_ARRAYS(keys, values)`

| 参数 | 类型 | 说明 |
|---|---|---|
| keys | ARRAY<K> | 键数组，参数位在前 |
| values | ARRAY<V> | 值数组，参数位在后，须与keys等长 |

返回：MAP<K, V>；键值按两数组的位置一一配对。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, MAP_FROM_ARRAYS(ARRAY['k'], ARRAY[1]) FROM bid;
```

输出：MAP<STRING, INT>；每行均为{k=1}。

| 输入 | 输出 | 说明 |
|---|---|---|
| MAP_FROM_ARRAYS(ARRAY['k'], ARRAY[1]) | {k=1} | 键数组与值数组按位置配对 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`MAP_FROM_ARRAYS`条目（SCALAR） |
| 求值逻辑 | `MapFromArraysFunction`的`eval()`（flink-table-runtime，经`BridgingSqlFunctionCallGen`调用） |

## velox实现

velox已有实现：sparksql套件的`map_from_arrays`（`velox/functions/sparksql/registration/RegisterMap.cpp`）。
