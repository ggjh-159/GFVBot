# PROCTIME

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

两重身份：DDL中`AS PROCTIME()`把列标记为处理时间属性；查询体内`PROCTIME()`逐行求值为当前处理时间，类型TIMESTAMP_LTZ。用于TTL判定、迟数据处理与处理时间的temporal join。

## 用法

签名：`PROCTIME()`——无参数；DDL中写作`AS PROCTIME()`。

无参数。

返回：TIMESTAMP_LTZ；当前行被处理时刻的时间戳，非确定。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, PROCTIME() FROM bid;
```

输出：TIMESTAMP_LTZ；每行被处理时刻的时间戳。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| — | 2026-09-11 10:23:41.209 | 每行重新生成（非确定），此处展示一次抽取的值 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`PROCTIME`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`PROCTIME`条目（SCALAR） |
| 求值逻辑 | `ExprCodeGenerator`特判——读取当前行的StreamRecord时间戳；查询体内引用时先改写为PROCTIME_MATERIALIZE |

## velox实现

velox仓库暂无对应实现（处理时间属性属算子层职责）。
