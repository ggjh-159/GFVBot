# NOT

分类：[逻辑函数](../index.md#逻辑函数) · 别名：—

## 定位与场景

逻辑否定：TRUE变FALSE、FALSE变TRUE；UNKNOWN仍为UNKNOWN。NOT的优先级低于比较谓词，对复合条件宜整体加括号以免歧义。

## 用法

签名：`NOT x`（一元前缀形式）

| 参数 | 类型 | 说明 |
|---|---|---|
| x | BOOLEAN | 被否定的布尔表达式；复合条件宜加括号 |

返回：BOOLEAN；TRUE与FALSE互换；输入为NULL（UNKNOWN）时结果仍为UNKNOWN。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, NOT (bid.auction > 5) FROM bid;
```

输出：BOOLEAN；每行对`auction > 5`取反（随行数据变化）。

示例（16行源的前8行，示意数据，末行补空值边界；前列为输入列，末两列为该行结果与说明）：

| auction | NOT (auction > 5) | 说明 |
|---|---|---|
| 3 | TRUE | 内层为FALSE，取反得TRUE |
| 19 | FALSE | 内层为TRUE，取反得FALSE |
| 8 | FALSE | 内层为TRUE，取反得FALSE |
| 1 | TRUE | 内层为FALSE，取反得TRUE |
| 14 | FALSE | 内层为TRUE，取反得FALSE |
| 7 | FALSE | 内层为TRUE，取反得FALSE |
| 11 | FALSE | 内层为TRUE，取反得FALSE |
| 20 | FALSE | 内层为TRUE，取反得FALSE |
| NULL | UNKNOWN | 内层为UNKNOWN，取反仍为UNKNOWN |

## 源码位置

GFV实现该表达式的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`NOT`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`NOT`条目（SCALAR） |
| 求值逻辑 | 经`ScalarOperatorGens`内联生成 |

## velox实现

velox已有内建`not`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
