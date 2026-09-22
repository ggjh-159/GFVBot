# TIMESTAMPDIFF

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

返回以指定单位——SECOND、MINUTE、HOUR、DAY、MONTH或YEAR——表示的整数时间差，方向为t2减t1；月/年差按日历计算。适用于延迟、时龄与时长的计算。

## 用法

签名：`TIMESTAMPDIFF(unit, t1, t2)`

| 参数 | 类型 | 说明 |
|---|---|---|
| unit | 关键字 | 差值单位：SECOND、MINUTE、HOUR、DAY、MONTH、YEAR |
| t1 | 时间类型 | 差值的减数侧 |
| t2 | 时间类型 | 差值的被减数侧；须与t1为同类时间类型 |

返回：BIGINT；以unit表示的整数差，方向为t2减t1。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, TIMESTAMPDIFF(SECOND, bid.dateTime, bid.dateTime) FROM bid;
```

输出：BIGINT；每行均为0——两侧是同一个时间戳。

示例（16行源的前8行，示意数据）：

| dateTime | TIMESTAMPDIFF(SECOND, dateTime, dateTime) | 说明 |
|---|---|---|
| 2026-07-03 09:15:22.480 | 0 | 两侧为同一时间戳，差恒为0 |
| 2026-07-05 10:41:07.123 | 0 | 同上 |
| 2026-07-09 11:02:59.640 | 0 | 同上 |
| 2026-07-03 13:27:44.005 | 0 | 同上 |
| 2026-07-12 14:50:18.872 | 0 | 同上 |
| 2026-07-07 15:33:51.309 | 0 | 同上 |
| 2026-07-09 16:19:36.551 | 0 | 同上 |
| 2026-07-11 17:44:29.918 | 0 | 同上 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`TIMESTAMP_DIFF`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`TIMESTAMP_DIFF`条目（SCALAR） |
| 求值逻辑 | `TimestampDiffCallGen`——按日历语义对两个时间做单位差运算 |

## velox实现

velox已有内建`date_diff`（`velox/functions/prestosql/registration/DateTimeFunctionsRegistration.cpp`）（单位常量拼写与Flink不同）。
