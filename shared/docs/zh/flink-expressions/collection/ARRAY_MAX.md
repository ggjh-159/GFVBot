# ARRAY_MAX

分类：[集合函数](../index.md#集合函数) · 别名：—

## 定位与场景

返回数组中的最大元素；NULL元素被跳过，数组为NULL得NULL。用于从每行候选值中提取最优值。

## 用法

签名：`ARRAY_MAX(arr)`

| 参数 | 类型 | 说明 |
|---|---|---|
| arr | ARRAY<T> | 待取最大值的数组 |

返回：T（元素类型）；NULL元素不参与比较。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_MAX(ARRAY[1,5,3]) FROM bid;
```

输出：INT；每行均为5。

| 输入 | 输出 | 说明 |
|---|---|---|
| ARRAY_MAX(ARRAY[1,5,3]) | 5 | 最大元素 |
| ARRAY_MAX(ARRAY[1,NULL,5]) | 5 | NULL元素被跳过 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`ARRAY_MAX`条目（SCALAR） |
| 求值逻辑 | `ArrayMaxFunction`的`eval()`（flink-table-runtime，经`BridgingSqlFunctionCallGen`调用） |

## velox实现

velox已有内建`array_max`（`velox/functions/prestosql/registration/ArrayFunctionsRegistration.cpp`）。
