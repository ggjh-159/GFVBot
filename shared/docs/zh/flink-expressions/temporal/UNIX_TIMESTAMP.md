# UNIX_TIMESTAMP

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

把时间字符串（可选格式）按会话时区转换为epoch秒；无参时返回当前epoch秒。适用于与unix风格API互通。

## 用法

签名：`UNIX_TIMESTAMP([s[, format]])`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 可选；待转换的时间字符串 |
| format | STRING | 可选；解析格式 |

返回：BIGINT；按会话时区读取文本得到的epoch秒，无参时返回当前epoch秒。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, UNIX_TIMESTAMP('2026-09-11 10:00:00') FROM bid;
```

输出：BIGINT；按会话时区读取'2026-09-11 10:00:00'的epoch秒——UTC+8下为1789092000。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| UNIX_TIMESTAMP('2026-09-11 10:00:00') | 1789092000 | 按UTC+8会话时区读取文本 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`UNIX_TIMESTAMP`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`UNIX_TIMESTAMP`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`静态方法（经`MethodCallGen`直调） |

## velox实现

velox已有实现：sparksql套件的`unix_timestamp`（`velox/functions/sparksql/registration/RegisterDatetime.cpp`）。
