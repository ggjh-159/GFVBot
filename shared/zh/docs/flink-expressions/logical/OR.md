# OR

分类：[逻辑函数](../index.md#逻辑函数) · 别名：—

## 定位与场景

三值逻辑下的逻辑或：任一操作数为TRUE即得TRUE；两者皆为FALSE才得FALSE；其余情形为UNKNOWN。用于放宽过滤条件与备选条件。

## 用法

签名：`a OR b`（中缀形式）

| 参数 | 类型 | 说明 |
|---|---|---|
| 左操作数 | BOOLEAN | 可为NULL，按三值逻辑参与运算 |
| 右操作数 | BOOLEAN | 可为NULL，按三值逻辑参与运算 |

返回：BOOLEAN；任一操作数为TRUE得TRUE，两者皆为FALSE得FALSE，其余得UNKNOWN（`NULL OR TRUE`为TRUE，`NULL OR FALSE`为UNKNOWN）。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction > 15) OR (bid.bidder < 10) FROM bid;
```

输出：BOOLEAN；`auction > 15`或`bidder < 10`成立时为true（随行数据变化）。

示例（16行源的前8行，示意数据，末两行补三值逻辑边界；前列为输入列，末两列为该行结果与说明）：

| auction | bidder | (auction > 15) OR (bidder < 10) | 说明 |
|---|---|---|---|
| 3 | 15 | FALSE | 两侧均为FALSE |
| 19 | 7 | TRUE | 两侧均为TRUE |
| 8 | 8 | TRUE | 右侧为TRUE |
| 1 | 42 | FALSE | 两侧均为FALSE |
| 14 | 23 | FALSE | 两侧均为FALSE |
| 7 | 2 | TRUE | 右侧为TRUE |
| 11 | 11 | FALSE | 两侧均为FALSE |
| 20 | 36 | TRUE | 左侧为TRUE |
| NULL | 7 | TRUE | 右侧TRUE压过UNKNOWN |
| NULL | 42 | UNKNOWN | 左侧UNKNOWN、右侧FALSE，得UNKNOWN |

## 源码位置

GFV实现该表达式的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`OR`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`OR`条目（SCALAR） |
| 求值逻辑 | 经`ScalarOperatorGens`内联生成 |

## velox实现

velox表达式内核将其作为特型`or`处理（`velox/expression/RegisterSpecialForm.cpp`），无独立函数注册。
