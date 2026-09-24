# ARRAY_CONTAINS

分类：[集合函数](../index.md#集合函数) · 别名：—

## 定位与场景

判断数组是否包含指定值：包含返回TRUE，不包含返回FALSE。适用于候选集合以列数据（而非字面量）形式出现时的成员判断。

## 用法

签名：`ARRAY_CONTAINS(arr, v)`

| 参数 | 类型 | 说明 |
|---|---|---|
| arr | ARRAY<T> | 待判断的数组 |
| v | T | 待查找的值，类型为数组元素类型 |

返回：BOOLEAN；包含得TRUE，不包含得FALSE。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_CONTAINS(ARRAY[1,2,3], 2) FROM bid;
```

输出：BOOLEAN；每行均为true。

| 输入 | 输出 | 说明 |
|---|---|---|
| ARRAY_CONTAINS(ARRAY[1,2,3], 2) | TRUE | 2在数组中 |
| ARRAY_CONTAINS(ARRAY[1,2,3], 9) | FALSE | 值不存在时返回FALSE |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`ARRAY_CONTAINS`条目（SCALAR） |
| 求值逻辑 | `ArrayContainsFunction`的`eval()`（flink-table-runtime，经`BridgingSqlFunctionCallGen`调用） |

## velox实现

velox已有内建`contains`（`velox/functions/prestosql/registration/ArrayFunctionsRegistration.cpp`）（sparksql套件注册`array_contains`）。
