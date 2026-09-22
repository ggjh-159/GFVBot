# NOW

分类：[时间函数](../index.md#时间函数) · 别名：`CURRENT_TIMESTAMP`

## 定位与场景

与CURRENT_TIMESTAMP同义——返回当前时刻的TIMESTAMP_LTZ，按会话时区呈现，每查询求值一次——但必须带括号写作`NOW()`。

## 用法

签名：`NOW()`——必须带括号；与`CURRENT_TIMESTAMP`同义。

无参数。

返回：TIMESTAMP_LTZ；整个查询固定一个时刻，按会话时区呈现。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, NOW() FROM bid;
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
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`NOW`条目（SCALAR） |
| 求值逻辑 | `CurrentTimePointCallGen`——与CURRENT_TIMESTAMP同载体，流模式下作为查询级常量注入 |

## velox实现

velox已有实现：sparksql套件的`current_timestamp`（`velox/functions/sparksql/registration/RegisterDatetime.cpp`）（即NOW的对应实现）。
