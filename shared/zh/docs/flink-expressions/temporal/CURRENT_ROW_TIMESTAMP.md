# CURRENT_ROW_TIMESTAMP

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

返回求值时逐行读取的TIMESTAMP_LTZ时钟——CURRENT_TIMESTAMP则是每查询固定一个时刻。Flink 1.19中必须带括号，否则解析器会将其当作列名。适用于摄入时间打标。

## 用法

签名：`CURRENT_ROW_TIMESTAMP()`——必须带括号。

无参数。

返回：TIMESTAMP_LTZ；每行求值时重新读取时钟，非确定。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CURRENT_ROW_TIMESTAMP() FROM bid;
```

输出：TIMESTAMP_LTZ；每行重新读取。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| — | 2026-09-11 10:23:41.209 | 每行重新生成（非确定），此处展示一次抽取的值 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`CURRENT_ROW_TIMESTAMP`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`CURRENT_ROW_TIMESTAMP`条目（SCALAR） |
| 求值逻辑 | `CurrentTimePointCallGen`的逐行模式——每行读取时钟 |

## velox实现

velox仓库暂无对应实现。
