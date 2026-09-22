# TEMPORAL_OVERLAPS

分类：[时间函数](../index.md#时间函数) · 别名：`OVERLAPS`

## 定位与场景

判断两个时间区间是否存在公共时刻：`(s1, e1) OVERLAPS (s2, e2)`；每一侧可为（起点，终点）或（起点，时长）。常用于排程冲突检测与窗口重叠判断。

## 用法

签名：`(s1, e1 | iv1) OVERLAPS (s2, e2 | iv2)`——中缀谓词形式。

| 参数 | 类型 | 说明 |
|---|---|---|
| s1, s2 | 时间类型 | 两区间的起点 |
| e1, e2 | 时间类型或INTERVAL | 区间终点，或与起点相加的时长 |

返回：BOOLEAN；两区间存在公共时刻为TRUE。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.dateTime, INTERVAL '1' HOUR) OVERLAPS (bid.dateTime, INTERVAL '1' DAY) FROM bid;
```

输出：BOOLEAN；本例恒为true——两窗口同起于`dateTime`，1小时的窗口被1天的窗口完全包含。

示例（16行源的前8行，示意数据）：

| dateTime | (dateTime, 1h) OVERLAPS (dateTime, 1d) | 说明 |
|---|---|---|
| 2026-07-03 09:15:22.480 | TRUE | 两窗口同起于该行`dateTime`，1小时窗口被1天窗口完全包含 |
| 2026-07-05 10:41:07.123 | TRUE | 同上 |
| 2026-07-09 11:02:59.640 | TRUE | 同上 |
| 2026-07-03 13:27:44.005 | TRUE | 同上 |
| 2026-07-12 14:50:18.872 | TRUE | 同上 |
| 2026-07-07 15:33:51.309 | TRUE | 同上 |
| 2026-07-09 16:19:36.551 | TRUE | 同上 |
| 2026-07-11 17:44:29.918 | TRUE | 同上 |

## 源码位置

GFV实现该表达式的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`TEMPORAL_OVERLAPS`条目（SCALAR） |
| 求值逻辑 | `TemporalOverlapsConverter`把OVERLAPS展开为区间边界的AND/OR比较树，经`ScalarOperatorGens`内联生成 |

## velox实现

velox仓库暂无对应实现。
