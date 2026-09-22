# AND

分类：[逻辑函数](../index.md#逻辑函数) · 别名：—

## 定位与场景

三值逻辑下的逻辑与：两操作数皆为TRUE才得TRUE；任一为FALSE即得FALSE；其余情形为UNKNOWN。复合WHERE、JOIN、HAVING谓词的基本构件。

## 用法

签名：`a AND b`（中缀形式）

| 参数 | 类型 | 说明 |
|---|---|---|
| 左操作数 | BOOLEAN | 可为NULL，按三值逻辑参与运算 |
| 右操作数 | BOOLEAN | 可为NULL，按三值逻辑参与运算 |

返回：BOOLEAN；两操作数皆为TRUE得TRUE，任一为FALSE得FALSE，其余得UNKNOWN（`NULL AND FALSE`为FALSE，`NULL AND TRUE`为UNKNOWN）。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction > 5) AND (bid.bidder < 40) FROM bid;
```

输出：BOOLEAN；`auction > 5`与`bidder < 40`同时成立时为true（随行数据变化）。

示例（16行源的前8行，示意数据，末两行补三值逻辑边界；前列为输入列，末两列为该行结果与说明）：

| auction | bidder | (auction > 5) AND (bidder < 40) | 说明 |
|---|---|---|---|
| 3 | 15 | FALSE | 左侧为FALSE，直接得FALSE |
| 19 | 7 | TRUE | 两侧均为TRUE |
| 8 | 8 | TRUE | 两侧均为TRUE |
| 1 | 42 | FALSE | 两侧均为FALSE |
| 14 | 23 | TRUE | 两侧均为TRUE |
| 7 | 2 | TRUE | 两侧均为TRUE |
| 11 | 11 | TRUE | 两侧均为TRUE |
| 20 | 36 | TRUE | 两侧均为TRUE |
| NULL | 15 | UNKNOWN | 左侧UNKNOWN、右侧TRUE，得UNKNOWN |
| NULL | 42 | FALSE | 右侧为FALSE，FALSE压过UNKNOWN得FALSE |

## 源码位置

GFV实现该表达式的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`AND`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`AND`条目（SCALAR） |
| 求值逻辑 | 经`ScalarOperatorGens`内联生成 |

## velox实现

velox表达式内核将其作为特型`and`处理（`velox/expression/RegisterSpecialForm.cpp`），无独立函数注册。
