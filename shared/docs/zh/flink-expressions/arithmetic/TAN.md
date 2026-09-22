# TAN

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回x的正切值，操作数为弧度制而非角度；用于斜率与方向计算。

## 用法

签名：`TAN(x)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | DOUBLE | 弧度制的角 |

返回：DOUBLE。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, TAN(0) FROM bid;
```

输出：DOUBLE；`TAN(0)`每行均为0.0。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| TAN(0) | 0.0 | 0弧度处正切为0 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`TAN`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`TAN`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`的静态方法（经`MethodCallGen`调用） |

## velox实现

velox已有内建`tan`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
