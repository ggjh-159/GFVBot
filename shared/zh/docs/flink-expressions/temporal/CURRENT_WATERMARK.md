# CURRENT_WATERMARK

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

返回给定rowtime属性的当前事件时间水位线，类型TIMESTAMP_LTZ。水位线尚未推进时返回NULL；对普通非rowtime列恒为NULL——入参须为声明为事件时间属性的时间列。适用于调试水位线进度与编写感知水位线的逻辑。

## 用法

签名：`CURRENT_WATERMARK(rowtime)`

| 参数 | 类型 | 说明 |
|---|---|---|
| rowtime | 时间属性列 | 须为事件时间（rowtime）属性 |

返回：TIMESTAMP_LTZ或NULL；水位线尚未推进或入参非rowtime属性时为NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CURRENT_WATERMARK(bid.dateTime) FROM bid;
```

输出：TIMESTAMP_LTZ或NULL；本例每行均为NULL——`dateTime`不是rowtime属性。

示例（16行源的前8行，示意数据）：

| dateTime | CURRENT_WATERMARK(dateTime) | 说明 |
|---|---|---|
| 2026-07-03 09:15:22.480 | NULL | `dateTime`不是rowtime属性，恒为NULL |
| 2026-07-05 10:41:07.123 | NULL | 同上 |
| 2026-07-09 11:02:59.640 | NULL | 同上 |
| 2026-07-03 13:27:44.005 | NULL | 同上 |
| 2026-07-12 14:50:18.872 | NULL | 同上 |
| 2026-07-07 15:33:51.309 | NULL | 同上 |
| 2026-07-09 16:19:36.551 | NULL | 同上 |
| 2026-07-11 17:44:29.918 | NULL | 同上 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`CURRENT_WATERMARK`条目（SCALAR） |
| 求值逻辑 | `ExprCodeGenerator`特判——读取输入StreamRecord上下文的当前水位线 |

## velox实现

velox仓库暂无对应实现（属算子水位线状态查询）。
