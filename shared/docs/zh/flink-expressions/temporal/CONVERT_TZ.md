# CONVERT_TZ

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

把无时区的时间戳字符串从一个时区换算到另一个时区，返回换算后的时间字符串。时区名取`java.util.TimeZone`的id。适用于把本地时间数据接入UTC管道或做反向转换。

## 用法

签名：`CONVERT_TZ(ts, fromTz, toTz)`

| 参数 | 类型 | 说明 |
|---|---|---|
| ts | STRING | 无时区的时间戳字符串 |
| fromTz | STRING | 源时区，取`java.util.TimeZone`的id |
| toTz | STRING | 目标时区，取`java.util.TimeZone`的id |

返回：STRING；换算到目标时区后的时间字符串。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CONVERT_TZ('2026-09-11 10:00:00', 'UTC', 'Asia/Shanghai') FROM bid;
```

输出：STRING；每行均为'2026-09-11 18:00:00'。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| CONVERT_TZ('2026-09-11 10:00:00', 'UTC', 'Asia/Shanghai') | 2026-09-11 18:00:00 | UTC的10点换算到Asia/Shanghai（UTC+8）为18点 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`CONVERT_TZ`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`CONVERT_TZ`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`静态方法（经`MethodCallGen`直调） |

## velox实现

velox仓库暂无对应实现。
