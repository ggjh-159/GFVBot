# DATE_FORMAT

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

用Java SimpleDateFormat风格的模式（如yyyy-MM-dd HH:mm:ss）格式化时间戳或时间字符串，返回STRING。适用于报表与分区列的定宽时间标签。

## 用法

签名：`DATE_FORMAT(ts, pattern)`

| 参数 | 类型 | 说明 |
|---|---|---|
| ts | TIMESTAMP/TIMESTAMP_LTZ/STRING | 待格式化的时间戳或时间字符串 |
| pattern | STRING | Java SimpleDateFormat风格的模式 |

返回：STRING；按给定模式渲染的文本。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, DATE_FORMAT(bid.dateTime, 'yyyy-MM-dd HH:mm:ss') FROM bid;
```

输出：STRING；每行按给定模式渲染的`dateTime`（随行数据变化）。

示例（16行源的前8行，示意数据）：

| dateTime | DATE_FORMAT(dateTime, 'yyyy-MM-dd HH:mm:ss') | 说明 |
|---|---|---|
| 2026-07-03 09:15:22.480 | 2026-07-03 09:15:22 | 模式不含毫秒，渲染到秒 |
| 2026-07-05 10:41:07.123 | 2026-07-05 10:41:07 | 同上 |
| 2026-07-09 11:02:59.640 | 2026-07-09 11:02:59 | 同上 |
| 2026-07-03 13:27:44.005 | 2026-07-03 13:27:44 | 同上 |
| 2026-07-12 14:50:18.872 | 2026-07-12 14:50:18 | 同上 |
| 2026-07-07 15:33:51.309 | 2026-07-07 15:33:51 | 同上 |
| 2026-07-09 16:19:36.551 | 2026-07-09 16:19:36 | 同上 |
| 2026-07-11 17:44:29.918 | 2026-07-11 17:44:29 | 同上 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`DATE_FORMAT`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`DATE_FORMAT`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`静态方法（经`MethodCallGen`直调） |

## velox实现

velox已有内建`date_format`（`velox/functions/prestosql/registration/DateTimeFunctionsRegistration.cpp`）（sparksql套件亦注册同名额）。
