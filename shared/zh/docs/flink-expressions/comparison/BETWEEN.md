# BETWEEN

分类：[比较函数](../index.md#比较函数) · 别名：—

## 定位与场景

`x BETWEEN lo AND hi`等价于`x >= lo AND x <= hi`，两端均为闭区间；任一操作数为NULL时结果为UNKNOWN。价格区间、时间窗口等范围过滤的直观写法。

## 用法

签名：`x BETWEEN lo AND hi`——x为被检表达式，lo、hi为与x同一可比较类型的下界与上界。

返回：BOOLEAN；x落在闭区间`[lo, hi]`内为TRUE；任一操作数为NULL时结果为UNKNOWN。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.price BETWEEN 10.00 AND 60.00 FROM bid;
```

输出：BOOLEAN；`price`落在10.00到60.00（含端点）内为true（随行数据变化）。

示例（16行源的前8行，示意数据，末行补空值边界；前列为输入列，末两列为该行结果与说明）：

| price | price BETWEEN 10.00 AND 60.00 | 说明 |
|---|---|---|
| 55.67 | TRUE | 落在闭区间内 |
| 12.50 | TRUE | 落在闭区间内 |
| 99.99 | FALSE | 高于上界 |
| 3.14 | FALSE | 低于下界 |
| 61.20 | FALSE | 高于上界 |
| 28.05 | TRUE | 落在闭区间内 |
| 77.77 | FALSE | 高于上界 |
| 45.00 | TRUE | 落在闭区间内 |
| NULL | UNKNOWN | 任一操作数为NULL得UNKNOWN |

## 源码位置

GFV实现该表达式的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`BETWEEN`条目；Sql到Rex转换阶段被改写为SEARCH RexCall（SARG范围） |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`BETWEEN`条目（SCALAR） |
| 求值逻辑 | 改写为SEARCH后由`SearchOperatorGen`展开为区间比较 |

## velox实现

velox已有内建`between`（`velox/functions/prestosql/registration/ComparisonFunctionsRegistration.cpp`）。
