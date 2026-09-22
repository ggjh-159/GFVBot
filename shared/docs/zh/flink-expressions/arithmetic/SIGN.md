# SIGN

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回x的符号：x为负得-1，为零得0，为正得1；结果类型随输入。用于由带符号数值派生方向标记。

## 用法

签名：`SIGN(x)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | 数值 | 待取符号的数值表达式 |

返回：-1、0或1；类型随输入。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, SIGN(bid.auction - 30) FROM bid;
```

输出：每行`auction - 30`的符号：-1、0或1（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | SIGN(auction - 30) | 说明 |
|---|---|---|
| 3 | -1 | 3-30=-27，为负 |
| 19 | -1 | 19-30=-11，为负 |
| 8 | -1 | 8-30=-22，为负 |
| 1 | -1 | 1-30=-29，为负 |
| 14 | -1 | 14-30=-16，为负 |
| 7 | -1 | 7-30=-23，为负 |
| 11 | -1 | 11-30=-19，为负 |
| 20 | -1 | 20-30=-10，为负 |
| SIGN(0) | 0 | 输入为0时符号为0 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`SIGN`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`SIGN`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`的静态方法（经`MethodCallGen`调用） |

## velox实现

velox已有内建`sign`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
