# GE

分类：[比较函数](../index.md#比较函数) · 别名：`>=`

## 定位与场景

排序谓词：左操作数大于等于右操作数时返回TRUE；任一侧为NULL时结果为UNKNOWN。常作为范围过滤的闭上界。

## 用法

签名：`a >= b`（中缀形式）

| 参数 | 类型 | 说明 |
|---|---|---|
| 左操作数 | 可比较且可排序的类型 | 数值、字符串、时间等 |
| 右操作数 | 可比较且可排序的类型 | 与左操作数可互相比较 |

返回：BOOLEAN；左操作数大于或等于右操作数为TRUE；任一侧为NULL时结果为UNKNOWN。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction >= bid.bidder FROM bid;
```

输出：BOOLEAN；`auction`不小于`bidder`时为true（随行数据变化）。

示例（16行源的前8行，示意数据，末行补空值边界；前列为输入列，末两列为该行结果与说明）：

| auction | bidder | auction >= bidder | 说明 |
|---|---|---|---|
| 3 | 15 | FALSE | 小于 |
| 19 | 7 | TRUE | 大于成立 |
| 8 | 8 | TRUE | 相等命中闭边界 |
| 1 | 42 | FALSE | 小于 |
| 14 | 23 | FALSE | 小于 |
| 7 | 2 | TRUE | 大于成立 |
| 11 | 11 | TRUE | 相等命中闭边界 |
| 20 | 36 | FALSE | 小于 |
| NULL | 8 | UNKNOWN | 任一侧为NULL得UNKNOWN |

## 源码位置

GFV实现该表达式的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`GREATER_THAN_OR_EQUAL`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`GREATER_THAN_OR_EQUAL`条目（SCALAR） |
| 求值逻辑 | 经`ScalarOperatorGens`内联生成 |

## velox实现

velox已有内建`gte`（`velox/functions/prestosql/registration/ComparisonFunctionsRegistration.cpp`）。
