# CURRENT_DATE

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

返回会话时区下的当前SQL日期，类型DATE；每查询求值一次，同一查询内所有行取同一值。适用于分区日过滤与到达日打标。

## 用法

签名：`CURRENT_DATE`——无括号的时间常量写法；类型DATE。

无参数。

返回：DATE；查询当日的日期，同一查询内固定不变。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CURRENT_DATE FROM bid;
```

输出：DATE；查询当日日期，16行完全相同。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| — | 2026-09-11 | 每查询求值一次，16行同值 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`CURRENT_DATE`条目（SCALAR） |
| 求值逻辑 | `CurrentTimePointCallGen`——流模式下作为查询级常量注入可复用成员，批模式在规划期折叠 |

## velox实现

velox已有内建`current_date`（`velox/functions/prestosql/registration/DateTimeFunctionsRegistration.cpp`）。
