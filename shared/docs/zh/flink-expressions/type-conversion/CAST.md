# CAST

分类：[类型转换函数](../index.md#类型转换函数) · 别名：—

## 定位与场景

显式类型转换，转换矩阵覆盖数值的拓宽与收窄、字符串与数值互转、字符串与时间互转、复合类型的重标注。无法转换时抛运行时错误；需要失败得NULL的静默语义时改用TRY_CAST。

## 用法

签名：`CAST(x AS t)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | 任意 | 待转换的值 |
| t | SQL类型 | 目标类型 |

返回：目标类型t的值；无法转换时抛运行时错误。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CAST(bid.auction AS VARCHAR) FROM bid;
```

输出：VARCHAR；每行`auction`的十进制数字（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末两列为该行结果与说明）：

| auction | CAST(auction AS VARCHAR) | 说明 |
|---|---|---|
| 3 | 3 | 整数转十进制字符串 |
| 19 | 19 | 整数转十进制字符串 |
| 8 | 8 | 整数转十进制字符串 |
| 1 | 1 | 整数转十进制字符串 |
| 14 | 14 | 整数转十进制字符串 |
| 7 | 7 | 整数转十进制字符串 |
| 11 | 11 | 整数转十进制字符串 |
| 20 | 20 | 整数转十进制字符串 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`CAST`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`CAST`条目（SCALAR） |
| 求值逻辑 | `ExprCodeGenerator`的CAST分支按源/目标类型对生成专用转换代码（数值/字符串/时间矩阵） |

## velox实现

velox表达式内核将其作为特型`cast`处理（`velox/expression/RegisterSpecialForm.cpp`），无独立函数注册。
