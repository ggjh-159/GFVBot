# PLUS

分类：[算术函数](../index.md#算术函数) · 别名：`+`

## 定位与场景

加法（中缀`+`）：支持数值加数值与时间类型加间隔，数值情形的结果类型按Flink类型系统拓宽。任一操作数为NULL时结果为NULL。派生指标中广泛使用——q1形态列`0.908 * price + 10`即为乘法之上的一个PLUS。

## 用法

签名：`a + b`（中缀加法）

| 参数 | 类型 | 说明 |
|---|---|---|
| 左操作数 | 数值或时间类型 | 加数；亦支持时间类型加间隔 |
| 右操作数 | 数值或间隔 | 加数 |

返回：和；数值情形按Flink类型系统拓宽结果类型。任一操作数为NULL时为NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction + bid.bidder FROM bid;
```

输出：BIGINT；每行的`auction + bidder`（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | bidder | auction + bidder | 说明 |
|---|---|---|---|
| 3 | 15 | 18 | 3+15=18 |
| 19 | 7 | 26 | 19+7=26 |
| 8 | 8 | 16 | 8+8=16 |
| 1 | 42 | 43 | 1+42=43 |
| 14 | 23 | 37 | 14+23=37 |
| 7 | 2 | 9 | 7+2=9 |
| 11 | 11 | 22 | 11+11=22 |
| 20 | 36 | 56 | 20+36=56 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`PLUS`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`PLUS`条目（SCALAR） |
| 求值逻辑 | 经`ScalarOperatorGens`内联生成 |

## velox实现

velox已有内建`plus`（`velox/functions/prestosql/registration/MathematicalOperatorsRegistration.cpp`）。
