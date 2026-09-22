# ARRAY

分类：[值构造函数](../index.md#值构造函数) · 别名：—

## 定位与场景

数组构造器：`ARRAY[v1, v2, ...]`把各元素统一为公共元素类型后生成数组值。用于把多列打包成一个数组值供下游数组函数使用。

## 用法

签名：`ARRAY[v1, v2, ...]`——构造器语法，非普通函数调用。

| 参数 | 类型 | 说明 |
|---|---|---|
| v1, v2, ... | 任意类型 | 数组元素，须统一为公共元素类型 |

返回：ARRAY<T>；T为各元素的公共类型。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY[bid.auction, bid.bidder, 99] FROM bid;
```

输出：ARRAY<BIGINT>；每行为`[auction, bidder, 99]`。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | bidder | ARRAY[auction, bidder, 99] |
|---|---|---|
| 3 | 15 | [3, 15, 99] |
| 19 | 7 | [19, 7, 99] |
| 8 | 8 | [8, 8, 99] |
| 1 | 42 | [1, 42, 99] |
| 14 | 23 | [14, 23, 99] |
| 7 | 2 | [7, 2, 99] |
| 11 | 11 | [11, 11, 99] |
| 20 | 36 | [20, 36, 99] |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`ARRAY`条目（SCALAR） |
| 求值逻辑 | 经`ExprCodeGenerator`的ARRAY_VALUE_CONSTRUCTOR分支内联为`GenericArrayData`构造 |

## velox实现

velox已有实现：sparksql套件的`array`（`velox/functions/sparksql/registration/RegisterArray.cpp`）（prestosql侧另有`array_constructor`）。
