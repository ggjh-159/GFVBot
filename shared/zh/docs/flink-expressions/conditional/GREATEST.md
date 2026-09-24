# GREATEST

分类：[条件函数](../index.md#条件函数) · 别名：—

## 定位与场景

返回参数中的最大值；任一参数为NULL则结果为NULL。常用于跨列归一化与钳制（如为计算结果设置下限）。

## 用法

签名：`GREATEST(v1, v2, ...)`

| 参数 | 类型 | 说明 |
|---|---|---|
| v1, v2, ... | 可比较类型 | 两个及以上同类型的值 |

返回：与参数同类型；全部参数中的最大值；任一参数为NULL则结果为NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, GREATEST(bid.auction, bid.bidder, 7) FROM bid;
```

输出：BIGINT；每行取`auction`、`bidder`与常量7三者中的最大值。

示例（16行源的前8行，示意数据，末行补空值边界；前列为输入列，末两列为该行结果与说明）：

| auction | bidder | GREATEST(auction, bidder, 7) | 说明 |
|---|---|---|---|
| 3 | 15 | 15 | 最大值来自bidder |
| 19 | 7 | 19 | 最大值来自auction |
| 8 | 8 | 8 | 最大值来自auction与bidder |
| 1 | 42 | 42 | 最大值来自bidder |
| 14 | 23 | 23 | 最大值来自bidder |
| 7 | 2 | 7 | 最大值来自auction与常量7 |
| 11 | 11 | 11 | 最大值来自auction与bidder |
| 20 | 36 | 36 | 最大值来自bidder |
| NULL | 8 | NULL | 任一参数为NULL得NULL |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配`BuiltInFunctionDefinitions`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`GREATEST`条目（SCALAR） |
| 求值逻辑 | `ExprCodeGenerator`经`generateGreatestLeast`内联为逐参数比较链 |

## velox实现

velox已有内建`greatest`（`velox/functions/prestosql/registration/GeneralFunctionsRegistration.cpp`）（NULL语义不同：velox版跳过NULL，Flink版任一参数为NULL即返回NULL）。
