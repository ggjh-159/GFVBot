# CEIL

分类：[算术函数](../index.md#算术函数) · 别名：`CEILING`

## 定位与场景

返回不小于x的最小整数，CEILING为同义拼法；时间形式`CEIL(ts TO unit)`把时间戳向上取整到指定单位的边界。用于容量、分页、批次等需要向上取整的场景。

## 用法

签名：`CEIL(x)`或`CEILING(x)`；另有时间形式`CEIL(ts TO unit)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | 数值 | 待向上取整的数值 |
| ts TO unit | TIMESTAMP与时间单位 | 时间形式：把时间戳向上取整到unit（如HOUR、DAY、MONTH）边界 |

返回：不小于x的最小整数；时间形式返回取整到单位边界的时间戳。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CEIL(bid.price) FROM bid;
```

输出：每行向上取整到下一个整数的十进制值，如55.01变56。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| price | CEIL(price) | 说明 |
|---|---|---|
| 55.67 | 56 | 小数部分非零，向上进一位 |
| 12.50 | 13 | 小数部分非零，向上进一位 |
| 99.99 | 100 | 进位使整数部分增一 |
| 3.14 | 4 | 小数部分非零，向上进一位 |
| 61.20 | 62 | 小数部分非零，向上进一位 |
| 28.05 | 29 | 小数部分非零，向上进一位 |
| 77.77 | 78 | 小数部分非零，向上进一位 |
| 45.00 | 45 | 已是整数，值不变 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`CEIL`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`CEIL`条目（SCALAR） |
| 求值逻辑 | 经`FloorCeilCallGen`生成：数值走`BuiltInMethods`的`FLOOR`/`CEIL`，时间截断走`UNIX_DATE`/`UNIX_TIMESTAMP`系列helper |

## velox实现

velox已有内建`ceil/ceiling`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
