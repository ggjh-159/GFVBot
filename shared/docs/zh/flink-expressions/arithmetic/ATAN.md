# ATAN

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回x的反正切主值，以弧度表示，值域为(-π/2, π/2)；用于把比率还原为角度。

## 用法

签名：`ATAN(x)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | DOUBLE | 正切值，取值任意 |

返回：DOUBLE，(-π/2, π/2)内的弧度。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ATAN(1) FROM bid;
```

输出：DOUBLE；`ATAN(1)`每行均为0.7853981633974483。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| ATAN(1) | 0.7853981633974483 | 正切值1对应弧度π/4 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`ATAN`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`ATAN`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`的静态方法（经`MethodCallGen`调用） |

## velox实现

velox已有内建`atan`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
