# ARRAY_POSITION

分类：[集合函数](../index.md#集合函数) · 别名：—

## 定位与场景

返回值在数组中首次出现位置的1基下标；值不存在得0，数组为NULL得NULL。用于查找已知元素的位置排名。

## 用法

签名：`ARRAY_POSITION(arr, v)`

| 参数 | 类型 | 说明 |
|---|---|---|
| arr | ARRAY<T> | 待查找的数组 |
| v | T | 待定位的值，类型为数组元素类型 |

返回：INT；1基下标，值不存在得0。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_POSITION(ARRAY[1,2,3], 2) FROM bid;
```

输出：INT；每行均为2。

| 输入 | 输出 | 说明 |
|---|---|---|
| ARRAY_POSITION(ARRAY[1,2,3], 2) | 2 | 1基下标：2是第二个元素 |
| ARRAY_POSITION(ARRAY[1,2,3], 5) | 0 | 值不存在得0 |
| ARRAY_POSITION(NULL, 2) | NULL | 数组为NULL得NULL |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`ARRAY_POSITION`条目（SCALAR） |
| 求值逻辑 | `ArrayPositionFunction`的`eval()`（flink-table-runtime，经`BridgingSqlFunctionCallGen`调用） |

## velox实现

velox已有内建`array_position`（`velox/functions/prestosql/registration/ArrayFunctionsRegistration.cpp`）。
