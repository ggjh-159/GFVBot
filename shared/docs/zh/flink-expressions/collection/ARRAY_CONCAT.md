# ARRAY_CONCAT

分类：[集合函数](../index.md#集合函数) · 别名：—

## 定位与场景

将两个元素类型相同的数组按参数顺序拼接为一个数组，保留全部元素且不去重。用于把两批同构数据合并为单一数组，例如向已有id列表追加一批id。

## 用法

签名：`ARRAY_CONCAT(a1, a2)`

| 参数 | 类型 | 说明 |
|---|---|---|
| a1 | ARRAY<T> | 拼接在前面的数组 |
| a2 | ARRAY<T> | 拼接在后面的数组，元素类型与a1相同 |

返回：ARRAY<T>；元素按参数顺序拼接，重复元素照常保留。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_CONCAT(ARRAY[1,2], ARRAY[3]) FROM bid;
```

输出：ARRAY<INT>；每行均为[1, 2, 3]。

| 输入 | 输出 | 说明 |
|---|---|---|
| ARRAY_CONCAT(ARRAY[1,2], ARRAY[3]) | [1, 2, 3] | 按参数顺序拼接两数组 |
| ARRAY_CONCAT(ARRAY[1,2], ARRAY[2]) | [1, 2, 2] | 两数组重复的元素不去重 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`ARRAY_CONCAT`条目（SCALAR） |
| 求值逻辑 | `ArrayConcatFunction`的`eval()`（flink-table-runtime，经`BridgingSqlFunctionCallGen`调用） |

## velox实现

velox已有内建`concat`（`velox/functions/prestosql/registration/ArrayConcatRegistration.cpp`）。
