# EXTRACT

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

从日期时间值中抽取指定字段——YEAR、QUARTER、MONTH、WEEK、DAY、DOY、DOW、HOUR、MINUTE、SECOND——返回整数。适用于按时间桶分组与派生日历特征。

## 用法

签名：`EXTRACT(field FROM ts)`——SQL标准语法形态。

| 参数 | 类型 | 说明 |
|---|---|---|
| field | 关键字 | 待抽取的字段：YEAR、QUARTER、MONTH、WEEK、DAY、DOY、DOW、HOUR、MINUTE、SECOND |
| ts | DATE/TIME/TIMESTAMP（或间隔） | 被抽取的日期时间值 |

返回：BIGINT；所抽取字段的整数值。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, EXTRACT(DAY FROM bid.dateTime) FROM bid;
```

输出：BIGINT；`dateTime`的日，每行1-31（随行数据变化）。

示例（16行源的前8行，示意数据）：

| dateTime | EXTRACT(DAY FROM dateTime) | 说明 |
|---|---|---|
| 2026-07-03 09:15:22.480 | 3 | 返回该行`dateTime`的日，取值1-31 |
| 2026-07-05 10:41:07.123 | 5 | 同上 |
| 2026-07-09 11:02:59.640 | 9 | 同上 |
| 2026-07-03 13:27:44.005 | 3 | 同上 |
| 2026-07-12 14:50:18.872 | 12 | 同上 |
| 2026-07-07 15:33:51.309 | 7 | 同上 |
| 2026-07-09 16:19:36.551 | 9 | 同上 |
| 2026-07-11 17:44:29.918 | 11 | 同上 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`EXTRACT`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`EXTRACT`条目（SCALAR） |
| 求值逻辑 | `ExtractCallGen`调`BuiltInMethods`.`UNIX_DATE_EXTRACT`（带时区时间戳走`EXTRACT_FROM_TIMESTAMP_TIME_ZONE`） |

## velox实现

GFV已在velox侧实现`extract`，注册于`velox/experimental/stateful/udf/Register.cpp`（实现于同目录`ExtractDateTime.h`）。
