# ABS

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回数值x的绝对值，结果类型与输入一致；用于度量偏离幅度、把带符号的差值归一化。输入为NULL时结果为NULL。

## 用法

签名：`ABS(x)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | 数值 | 待取绝对值的数值表达式 |

返回：与输入同类型；输入为NULL时为NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ABS(bid.auction - 30) FROM bid;
```

输出：BIGINT；每行的`ABS(auction - 30)`（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | ABS(auction - 30) | 说明 |
|---|---|---|
| 3 | 27 | 3-30=-27，绝对值为27 |
| 19 | 11 | 19-30=-11，绝对值为11 |
| 8 | 22 | 8-30=-22，绝对值为22 |
| 1 | 29 | 1-30=-29，绝对值为29 |
| 14 | 16 | 14-30=-16，绝对值为16 |
| 7 | 23 | 7-30=-23，绝对值为23 |
| 11 | 19 | 11-30=-19，绝对值为19 |
| 20 | 10 | 20-30=-10，绝对值为10 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`ABS`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`ABS`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`的静态方法（经`MethodCallGen`调用） |

## velox实现

velox已有内建`abs`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
