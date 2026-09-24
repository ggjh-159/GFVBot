# FLOOR

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回不大于x的最大整数；时间形式`FLOOR(ts TO unit)`把时间戳向下截断到指定单位（HOUR、DAY、MONTH等）的边界。用于把时间或数值对齐到桶边界。

## 用法

签名：`FLOOR(x)`；另有时间形式`FLOOR(ts TO unit)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | 数值 | 待向下取整的数值 |
| ts TO unit | TIMESTAMP与时间单位 | 时间形式：把时间戳向下截断到unit（如HOUR、DAY、MONTH）边界 |

返回：不大于x的最大整数；时间形式返回截断到单位边界的时间戳。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, FLOOR(bid.price) FROM bid;
```

输出：每行去掉小数部分的十进制值，如55.67变55。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| price | FLOOR(price) | 说明 |
|---|---|---|
| 55.67 | 55 | 舍去小数部分0.67 |
| 12.50 | 12 | 舍去小数部分 |
| 99.99 | 99 | 舍去小数部分 |
| 3.14 | 3 | 舍去小数部分 |
| 61.20 | 61 | 舍去小数部分 |
| 28.05 | 28 | 舍去小数部分 |
| 77.77 | 77 | 舍去小数部分 |
| 45.00 | 45 | 已是整数，值不变 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`FLOOR`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`FLOOR`条目（SCALAR） |
| 求值逻辑 | 经`FloorCeilCallGen`生成：数值走`BuiltInMethods`的`FLOOR`/`CEIL`，时间截断走`UNIX_DATE`/`UNIX_TIMESTAMP`系列helper |

## velox实现

velox已有内建`floor`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
