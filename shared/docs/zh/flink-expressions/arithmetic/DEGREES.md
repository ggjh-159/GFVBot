# DEGREES

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

把弧度值x换算为角度，即x乘以180/π；用于将三角函数的弧度输出换算为角度单位。

## 用法

签名：`DEGREES(x)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | DOUBLE | 弧度值 |

返回：DOUBLE；对应的角度值。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, DEGREES(1) FROM bid;
```

输出：DOUBLE；`DEGREES(1)`每行均为57.29577951308232。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| DEGREES(1) | 57.29577951308232 | 1弧度约57.2958度 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`DEGREES`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`DEGREES`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`的静态方法（经`MethodCallGen`调用） |

## velox实现

velox已有内建`degrees`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
