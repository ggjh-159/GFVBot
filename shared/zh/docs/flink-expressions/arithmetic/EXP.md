# EXP

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回e的x次幂；用于指数增长/衰减模型与softmax类权重计算。

## 用法

签名：`EXP(x)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | DOUBLE | 指数 |

返回：DOUBLE。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, EXP(2) FROM bid;
```

输出：DOUBLE；`EXP(2)`每行均为7.38905609893065。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| EXP(2) | 7.38905609893065 | e的2次幂 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`EXP`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`EXP`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`的静态方法（经`MethodCallGen`调用） |

## velox实现

velox已有内建`exp`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
