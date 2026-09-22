# ARRAY_REMOVE

分类：[集合函数](../index.md#集合函数) · 别名：—

## 定位与场景

删除数组中所有与指定值相等的元素，其余元素保持原顺序。用于对打标数据做黑名单过滤。

## 用法

签名：`ARRAY_REMOVE(arr, v)`

| 参数 | 类型 | 说明 |
|---|---|---|
| arr | ARRAY<T> | 原数组 |
| v | T | 待删除的值，类型为数组元素类型 |

返回：ARRAY<T>；命中值的所有出现一并删除。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_REMOVE(ARRAY[1,2,1], 1) FROM bid;
```

输出：ARRAY<INT>；每行均为[2]。

| 输入 | 输出 | 说明 |
|---|---|---|
| ARRAY_REMOVE(ARRAY[1,2,1], 1) | [2] | 1的两次出现全部删除 |
| ARRAY_REMOVE(ARRAY[1,2], 9) | [1, 2] | 值未出现时数组原样返回 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`ARRAY_REMOVE`条目（SCALAR） |
| 求值逻辑 | `ArrayRemoveFunction`的`eval()`（flink-table-runtime，经`BridgingSqlFunctionCallGen`调用） |

## velox实现

velox已有内建`array_remove`（`velox/functions/prestosql/registration/ArrayFunctionsRegistration.cpp`）。
