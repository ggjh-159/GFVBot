# MINUS

分类：[算术函数](../index.md#算术函数) · 别名：`-`

## 定位与场景

减法（中缀`-`）：支持数值减数值、时间减间隔与间隔减间隔。任一操作数为NULL时结果为NULL。用于差值与居中取值。

## 用法

签名：`a - b`（中缀减法）

| 参数 | 类型 | 说明 |
|---|---|---|
| 左操作数 | 数值、时间或间隔 | 被减数；支持数值、时间减间隔、间隔减间隔 |
| 右操作数 | 数值或间隔 | 减数 |

返回：差；数值、时间或间隔，类型按操作数组合推导。任一操作数为NULL时为NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction - bid.bidder FROM bid;
```

输出：BIGINT；每行的`auction - bidder`（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | bidder | auction - bidder | 说明 |
|---|---|---|---|
| 3 | 15 | -12 | 被减数小于减数，差为负 |
| 19 | 7 | 12 | 差为正 |
| 8 | 8 | 0 | 两数相等，差为0 |
| 1 | 42 | -41 | 被减数小于减数，差为负 |
| 14 | 23 | -9 | 被减数小于减数，差为负 |
| 7 | 2 | 5 | 差为正 |
| 11 | 11 | 0 | 两数相等，差为0 |
| 20 | 36 | -16 | 被减数小于减数，差为负 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`MINUS`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`MINUS`条目（SCALAR） |
| 求值逻辑 | 经`ScalarOperatorGens`内联生成 |

## velox实现

velox已有内建`minus`（`velox/functions/prestosql/registration/MathematicalOperatorsRegistration.cpp`）。
