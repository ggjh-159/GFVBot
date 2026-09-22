# FROM_UNIXTIME

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

把epoch秒（BIGINT）格式化为时间字符串，可选格式模式；渲染文本随会话时区变化。适用于把epoch列渲染成可读形式。

## 用法

签名：`FROM_UNIXTIME(unixtime[, format])`

| 参数 | 类型 | 说明 |
|---|---|---|
| unixtime | BIGINT | epoch秒 |
| format | STRING | 可选的格式模式 |

返回：STRING；按会话时区渲染的时间文本。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, FROM_UNIXTIME(1760000000) FROM bid;
```

输出：STRING；1760000000在UTC下渲染为'2025-10-09 12:26:40'——文本随会话时区变化（Asia/Shanghai为'2025-10-09 20:26:40'）。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| FROM_UNIXTIME(1760000000) | 2025-10-09 12:26:40 | UTC会话时区下的渲染 |
| FROM_UNIXTIME(1760000000) | 2025-10-09 20:26:40 | Asia/Shanghai会话时区下的渲染 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`FROM_UNIXTIME`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`FROM_UNIXTIME`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`静态方法（经`MethodCallGen`直调） |

## velox实现

velox已有实现：sparksql套件的`from_unixtime`（`velox/functions/sparksql/registration/RegisterDatetime.cpp`）（返回字符串，与Flink一致）。
