# ARRAY_DISTINCT

分类：[集合函数](../index.md#集合函数) · 别名：—

## 定位与场景

去除数组中的重复元素，各唯一元素按首次出现的顺序保留。用于对标签列表、id列表去重。

## 用法

签名：`ARRAY_DISTINCT(arr)`

| 参数 | 类型 | 说明 |
|---|---|---|
| arr | ARRAY<T> | 待去重的数组 |

返回：ARRAY<T>；重复元素仅保留首次出现的一份。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_DISTINCT(ARRAY[1,2,2,3]) FROM bid;
```

输出：ARRAY<INT>；每行均为[1, 2, 3]。

| 输入 | 输出 | 说明 |
|---|---|---|
| ARRAY_DISTINCT(ARRAY[1,2,2,3]) | [1, 2, 3] | 重复的2仅保留一次 |
| ARRAY_DISTINCT(ARRAY[2,1,2]) | [2, 1] | 按首次出现顺序保留 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`ARRAY_DISTINCT`条目（SCALAR） |
| 求值逻辑 | `ArrayDistinctFunction`的`eval()`（flink-table-runtime，经`BridgingSqlFunctionCallGen`调用） |

## velox实现

velox已有内建`array_distinct`（`velox/functions/prestosql/registration/ArrayFunctionsRegistration.cpp`）。
