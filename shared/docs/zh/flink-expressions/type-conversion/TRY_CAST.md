# TRY_CAST

分类：[类型转换函数](../index.md#类型转换函数) · 别名：—

## 定位与场景

与CAST相同的转换矩阵，但转换失败得NULL而非抛错。适用于清洗可能含非法值的列，不使作业因个别行转换失败而中断。

## 用法

签名：`TRY_CAST(x AS t)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | 任意 | 待转换的值 |
| t | SQL类型 | 目标类型 |

返回：目标类型t的值；无法转换时得NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, TRY_CAST('bid.extra' AS INT) FROM bid;
```

输出：INT；每行均为NULL——字面量'bid.extra'不是合法整数。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| TRY_CAST('bid.extra' AS INT) | NULL | 字面量非合法整数，失败得NULL而非报错 |
| TRY_CAST('123' AS INT) | 123 | 合法整数转换成功 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`TRY_CAST`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`TRY_CAST`条目（SCALAR） |
| 求值逻辑 | 与CAST同一codegen路径，外加失败得NULL的包装 |

## velox实现

velox表达式内核将其作为特型`try_cast`处理（`velox/expression/RegisterSpecialForm.cpp`），无独立函数注册。
