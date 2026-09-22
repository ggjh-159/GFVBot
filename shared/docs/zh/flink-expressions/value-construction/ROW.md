# ROW

分类：[值构造函数](../index.md#值构造函数) · 别名：—

## 定位与场景

行构造器：`ROW(v1, v2, ...)`生成匿名的复合值，字段名默认为f0、f1等，可用AS重命名。用于把一同流转的异构值打包。

## 用法

签名：`ROW(v1, v2, ...)`——行构造器语法。

| 参数 | 类型 | 说明 |
|---|---|---|
| v1, v2, ... | 任意类型 | 行的各字段，类型可不同；字段名默认f0、f1…，可用AS重命名 |

返回：ROW<T1, T2, ...>；各字段类型可以不同。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ROW(1, 'a', bid.auction) FROM bid;
```

输出：ROW<INT, STRING, BIGINT>；每行为`(1, 'a', auction)`。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | ROW(1, 'a', auction) |
|---|---|
| 3 | (1, a, 3) |
| 19 | (1, a, 19) |
| 8 | (1, a, 8) |
| 1 | (1, a, 1) |
| 14 | (1, a, 14) |
| 7 | (1, a, 7) |
| 11 | (1, a, 11) |
| 20 | (1, a, 20) |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`ROW`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`ROW`条目（SCALAR） |
| 求值逻辑 | 经`ExprCodeGenerator`的ROW分支内联为`GenericRowData`构造 |

## velox实现

velox表达式内核将其作为特型`row_constructor`处理（`velox/expression/RegisterSpecialForm.cpp`），无独立函数注册。
