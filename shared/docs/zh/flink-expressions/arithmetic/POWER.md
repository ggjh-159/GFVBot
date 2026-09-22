# POWER

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回base的exp次幂，结果为DOUBLE；用于多项式特征与复利类公式。

## 用法

签名：`POWER(base, exp)`

| 参数 | 类型 | 说明 |
|---|---|---|
| base | 数值 | 底数 |
| exp | 数值 | 指数 |

返回：DOUBLE。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, POWER(2, 10) FROM bid;
```

输出：DOUBLE；`POWER(2, 10)`每行均为1024.0。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| POWER(2, 10) | 1024.0 | 2的10次幂 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`POWER`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`POWER`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`的静态方法（经`MethodCallGen`调用） |

## velox实现

velox已有内建`power`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
