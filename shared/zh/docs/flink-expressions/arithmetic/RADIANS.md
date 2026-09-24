# RADIANS

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

把角度值x换算为弧度，即x乘以π/180；用于将以度输入的值换算后供以弧度计的三角函数使用。

## 用法

签名：`RADIANS(x)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | DOUBLE | 角度值 |

返回：DOUBLE；对应的弧度值。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, RADIANS(90) FROM bid;
```

输出：DOUBLE；`RADIANS(90)`每行均为1.5707963267948966。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| RADIANS(90) | 1.5707963267948966 | 90度即π/2弧度 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`RADIANS`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`RADIANS`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`的静态方法（经`MethodCallGen`调用） |

## velox实现

velox已有内建`radians`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
