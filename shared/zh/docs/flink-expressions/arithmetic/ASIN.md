# ASIN

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回x的反正弦主值，以弧度表示，值域为[-π/2, π/2]。输入须落在[-1, 1]内，超出该域（|x| > 1）返回NULL；用于对正弦类特征求逆。

## 用法

签名：`ASIN(x)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | DOUBLE | 正弦值，有效域为[-1, 1] |

返回：DOUBLE，[-π/2, π/2]内的弧度；|x| > 1时为NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ASIN(0.5) FROM bid;
```

输出：DOUBLE；`ASIN(0.5)`每行均为0.5235987755982989。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| ASIN(0.5) | 0.5235987755982989 | 正弦值0.5对应弧度π/6 |
| ASIN(2) | NULL | 输入超出[-1, 1]，返回NULL |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`ASIN`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`ASIN`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`的静态方法（经`MethodCallGen`调用） |

## velox实现

velox已有内建`asin`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
