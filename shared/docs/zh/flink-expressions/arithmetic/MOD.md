# MOD

分类：[算术函数](../index.md#算术函数) · 别名：`%`

## 定位与场景

返回除法的余数，支持函数形式`MOD(a, b)`与中缀`a % b`；余数符号与被除数一致，除数为0时报错。常用于分桶（如`MOD(id, n)`做分片或采样）、周期循环与奇偶判断。

## 用法

签名：`MOD(a, b)`或`a % b`

| 参数 | 类型 | 说明 |
|---|---|---|
| a | 整型或DECIMAL | 被除数 |
| b | 整型或DECIMAL | 除数，为0时报错 |

返回：余数，符号与被除数一致；类型随操作数。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, MOD(bid.auction, 7) FROM bid;
```

输出：BIGINT；`auction / 7`的余数，每行0-6（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | MOD(auction, 7) | 说明 |
|---|---|---|
| 3 | 3 | 3=0×7+3 |
| 19 | 5 | 19=2×7+5 |
| 8 | 1 | 8=1×7+1 |
| 1 | 1 | 1=0×7+1 |
| 14 | 0 | 整除，余数为0 |
| 7 | 0 | 整除，余数为0 |
| 11 | 4 | 11=1×7+4 |
| 20 | 6 | 20=2×7+6 |
| MOD(-19, 7) | -5 | 余数符号与被除数一致 |
| MOD(7, 0) | 报错 | 除数为0 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`MOD`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`MOD`条目（SCALAR） |
| 求值逻辑 | 经`ScalarOperatorGens`内联生成 |

## velox实现

velox已有内建`mod`（`velox/functions/prestosql/registration/MathematicalOperatorsRegistration.cpp`）。
