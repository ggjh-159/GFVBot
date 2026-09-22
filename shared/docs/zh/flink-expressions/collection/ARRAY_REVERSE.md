# ARRAY_REVERSE

分类：[集合函数](../index.md#集合函数) · 别名：—

## 定位与场景

反转数组的元素顺序，原数组的末位元素成为结果的首位。用于把追加序的列表按最新在前展示。

## 用法

签名：`ARRAY_REVERSE(arr)`

| 参数 | 类型 | 说明 |
|---|---|---|
| arr | ARRAY<T> | 待反转的数组 |

返回：ARRAY<T>；元素顺序整体反转。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_REVERSE(ARRAY[1,2,3]) FROM bid;
```

输出：ARRAY<INT>；每行均为[3, 2, 1]。

| 输入 | 输出 | 说明 |
|---|---|---|
| ARRAY_REVERSE(ARRAY[1,2,3]) | [3, 2, 1] | 元素顺序整体反转 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`ARRAY_REVERSE`条目（SCALAR） |
| 求值逻辑 | `ArrayReverseFunction`的`eval()`（flink-table-runtime，经`BridgingSqlFunctionCallGen`调用） |

## velox实现

velox仓库暂无对应实现。
