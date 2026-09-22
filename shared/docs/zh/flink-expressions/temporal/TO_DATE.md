# TO_DATE

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

把日期字符串解析为DATE，默认格式yyyy-MM-dd。适用于把文本日期转成可做日期运算与分区的值。

## 用法

签名：`TO_DATE(s[, format])`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 日期字符串，默认格式yyyy-MM-dd |
| format | STRING | 可选的解析格式 |

返回：DATE；解析得到的日期值。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, TO_DATE('2026-09-11') FROM bid;
```

输出：DATE；每行均为2026-09-11。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| TO_DATE('2026-09-11') | 2026-09-11 | 按默认格式yyyy-MM-dd解析 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`TO_DATE`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`TO_DATE`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`静态方法（经`MethodCallGen`直调） |

## velox实现

velox仓库暂无对应实现。
