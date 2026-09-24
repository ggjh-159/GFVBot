# ARRAY_UNION

分类：[集合函数](../index.md#集合函数) · 别名：—

## 定位与场景

对两个数组求并集并去重，结果中每个元素至多出现一次。用于合并两个来源的标签集合。

## 用法

签名：`ARRAY_UNION(a1, a2)`

| 参数 | 类型 | 说明 |
|---|---|---|
| a1 | ARRAY<T> | 第一个数组 |
| a2 | ARRAY<T> | 第二个数组，元素类型与a1相同 |

返回：ARRAY<T>；并集结果不含重复元素。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_UNION(ARRAY[1,2], ARRAY[2,3]) FROM bid;
```

输出：ARRAY<INT>；每行均为[1, 2, 3]。

| 输入 | 输出 | 说明 |
|---|---|---|
| ARRAY_UNION(ARRAY[1,2], ARRAY[2,3]) | [1, 2, 3] | 两数组共同的2在结果中仅出现一次 |
| ARRAY_UNION(ARRAY[1,1], ARRAY[2]) | [1, 2] | 数组内部的重复同样被去重 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`ARRAY_UNION`条目（SCALAR） |
| 求值逻辑 | `ArrayUnionFunction`的`eval()`（flink-table-runtime，经`BridgingSqlFunctionCallGen`调用） |

## velox实现

velox已有内建`array_union`（`velox/functions/prestosql/registration/ArrayFunctionsRegistration.cpp`）。
