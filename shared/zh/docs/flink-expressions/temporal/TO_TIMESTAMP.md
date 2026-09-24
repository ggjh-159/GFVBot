# TO_TIMESTAMP

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

把时间戳字符串解析为TIMESTAMP，默认格式yyyy-MM-dd HH:mm:ss，按会话时区解释文本。适用于把文本时间戳转成可开窗的值。

## 用法

签名：`TO_TIMESTAMP(s[, format])`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 时间戳字符串，默认格式yyyy-MM-dd HH:mm:ss |
| format | STRING | 可选的解析格式 |

返回：TIMESTAMP；解析得到的时间戳值。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, TO_TIMESTAMP('2026-09-11 10:00:00') FROM bid;
```

输出：TIMESTAMP；每行均为2026-09-11 10:00:00。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| TO_TIMESTAMP('2026-09-11 10:00:00') | 2026-09-11 10:00:00 | 按默认格式yyyy-MM-dd HH:mm:ss解析 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`TO_TIMESTAMP`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`TO_TIMESTAMP`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`静态方法（经`MethodCallGen`直调） |

## velox实现

velox仓库暂无对应实现。
