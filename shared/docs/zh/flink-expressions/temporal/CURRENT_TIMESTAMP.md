# CURRENT_TIMESTAMP

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

返回当前时刻，类型为TIMESTAMP WITH LOCAL TIME ZONE（TIMESTAMP_LTZ），按会话时区呈现；每查询求值一次，同一查询内所有行取同一值；不带括号。与`NOW()`同义。

## 用法

签名：`CURRENT_TIMESTAMP`——无括号的时间常量写法；类型TIMESTAMP_LTZ。

无参数。

返回：TIMESTAMP_LTZ；整个查询固定一个时刻，按会话时区呈现。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CURRENT_TIMESTAMP FROM bid;
```

输出：TIMESTAMP_LTZ；整个查询固定一个时刻——16行完全相同。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| — | 2026-09-11 10:23:41.209 | 每查询求值一次，16行同值 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`CURRENT_TIMESTAMP`条目（SCALAR） |
| 求值逻辑 | `CurrentTimePointCallGen`——流模式下作为查询级常量注入可复用成员，批模式在规划期折叠 |

## velox实现

velox已有实现：sparksql套件的`current_timestamp`（`velox/functions/sparksql/registration/RegisterDatetime.cpp`）。
