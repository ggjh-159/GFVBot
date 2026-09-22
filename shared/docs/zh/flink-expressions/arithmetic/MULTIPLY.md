# MULTIPLY

分类：[算术函数](../index.md#算术函数) · 别名：`*`

## 定位与场景

数值乘法（中缀`*`）。DECIMAL操作数参与时，结果的精度与小数位由操作数推导；任一操作数为NULL时结果为NULL。用于数量缩放，如汇率换算、单价乘数量与加权特征。

## 用法

签名：`a * b`（中缀乘法）

| 参数 | 类型 | 说明 |
|---|---|---|
| 左操作数 | 数值 | 乘数 |
| 右操作数 | 数值 | 被乘数；DECIMAL参与时结果的精度与小数位由两操作数推导 |

返回：乘积；类型按操作数推导。任一操作数为NULL时为NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction * 3 FROM bid;
```

输出：BIGINT；每行的`auction * 3`（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | auction * 3 | 说明 |
|---|---|---|
| 3 | 9 | 3×3=9 |
| 19 | 57 | 19×3=57 |
| 8 | 24 | 8×3=24 |
| 1 | 3 | 1×3=3 |
| 14 | 42 | 14×3=42 |
| 7 | 21 | 7×3=21 |
| 11 | 33 | 11×3=33 |
| 20 | 60 | 20×3=60 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`TIMES`条目（SCALAR） |
| 求值逻辑 | 经`ScalarOperatorGens`内联生成 |

## velox实现

velox已有内建`multiply`（`velox/functions/prestosql/registration/MathematicalOperatorsRegistration.cpp`）。
