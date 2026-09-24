# ATAN2

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

双参数反正切：返回点(y, x)的辐角，以弧度表示，值域为[-π, π]。与ATAN不同，ATAN2依据两个操作数的符号选定象限，能区分对角方向的角；用于由坐标差计算方位角。

## 用法

签名：`ATAN2(y, x)`

| 参数 | 类型 | 说明 |
|---|---|---|
| y | DOUBLE | 点的纵坐标 |
| x | DOUBLE | 点的横坐标 |

返回：DOUBLE，[-π, π]内的弧度。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ATAN2(1, 1) FROM bid;
```

输出：DOUBLE；`ATAN2(1, 1)`每行均为0.7853981633974483。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| ATAN2(1, 1) | 0.7853981633974483 | 点(1, 1)在第一象限，辐角为π/4 |
| ATAN2(1, -1) | 2.356194490192345 | x为负、y为正，辐角落在第二象限（3π/4） |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`ATAN2`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`ATAN2`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`的静态方法（经`MethodCallGen`调用） |

## velox实现

velox已有内建`atan2`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
