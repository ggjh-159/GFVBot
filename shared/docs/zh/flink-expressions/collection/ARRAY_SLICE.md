# ARRAY_SLICE

分类：[集合函数](../index.md#集合函数) · 别名：—

## 定位与场景

取数组从start到end（含两端点）的连续子数组，start与end均为1基下标。用于分页截取与掐头去尾。

## 用法

签名：`ARRAY_SLICE(arr, start[, end])`

| 参数 | 类型 | 说明 |
|---|---|---|
| arr | ARRAY<T> | 待截取的数组 |
| start | INT | 起始下标，1基，含端点 |
| end | INT | 可选；结束下标，1基，含端点 |

返回：ARRAY<T>；截取范围为1基闭区间。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_SLICE(ARRAY[1,2,3,4], 2, 3) FROM bid;
```

输出：ARRAY<INT>；每行均为[2, 3]。

| 输入 | 输出 | 说明 |
|---|---|---|
| ARRAY_SLICE(ARRAY[1,2,3,4], 2, 3) | [2, 3] | 1基含端点：取第2、3个元素 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`ARRAY_SLICE`条目（SCALAR） |
| 求值逻辑 | `ArraySliceFunction`的`eval()`（flink-table-runtime，经`BridgingSqlFunctionCallGen`调用） |

## velox实现

velox仓库暂无对应实现。
