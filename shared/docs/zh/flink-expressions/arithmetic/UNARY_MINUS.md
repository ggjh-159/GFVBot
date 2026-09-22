# UNARY_MINUS

分类：[算术函数](../index.md#算术函数) · 别名：`-x`

## 定位与场景

数值的一元取负（前缀`-x`），结果类型与操作数一致；输入NULL仍得NULL。用于翻转指标符号，使差值方向更直观（如亏损、迟到）。

## 用法

签名：`-x`（前缀取负）

| 参数 | 类型 | 说明 |
|---|---|---|
| x | 数值 | 待取负的操作数，任意数值类型 |

返回：与操作数同类型；输入为NULL时为NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, -bid.auction FROM bid;
```

输出：BIGINT；每行取负的`auction`。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | -auction | 说明 |
|---|---|---|
| 3 | -3 | 3的相反数 |
| 19 | -19 | 19的相反数 |
| 8 | -8 | 8的相反数 |
| 1 | -1 | 1的相反数 |
| 14 | -14 | 14的相反数 |
| 7 | -7 | 7的相反数 |
| 11 | -11 | 11的相反数 |
| 20 | -20 | 20的相反数 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`MINUS_PREFIX`条目（SCALAR） |
| 求值逻辑 | 经`ScalarOperatorGens`内联生成 |

## velox实现

velox已有内建`negate`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
