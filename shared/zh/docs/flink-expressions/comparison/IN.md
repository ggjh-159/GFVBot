# IN

分类：[比较函数](../index.md#比较函数) · 别名：—

## 定位与场景

左操作数等于列表中任一元素即返回TRUE；无匹配且任一元素（或操作数）为NULL时结果为UNKNOWN。适合小型白名单/黑名单过滤；planner可能将其改写为SEARCH/SARG查找。

## 用法

签名：`x IN (v1, v2, ...)`——x为被检表达式，v1、v2、…为与x同一可比较类型的列表元素。

返回：BOOLEAN；x等于任一元素为TRUE；无匹配且任一处为NULL时结果为UNKNOWN。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction IN (1, 5, 9, 13) FROM bid;
```

输出：BOOLEAN；`auction`为1、5、9或13时为true（随行数据变化）。

示例（16行源的前8行，示意数据，末行补空值边界；前列为输入列，末两列为该行结果与说明）：

| auction | auction IN (1, 5, 9, 13) | 说明 |
|---|---|---|
| 3 | FALSE | 无匹配且列表无NULL，得FALSE |
| 19 | FALSE | 无匹配 |
| 8 | FALSE | 无匹配 |
| 1 | TRUE | 命中列表元素1 |
| 14 | FALSE | 无匹配 |
| 7 | FALSE | 无匹配 |
| 11 | FALSE | 无匹配 |
| 20 | FALSE | 无匹配 |
| NULL | UNKNOWN | 无匹配且操作数为NULL得UNKNOWN |

## 源码位置

GFV实现该表达式的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`IN`条目；Sql到Rex转换阶段被改写为SEARCH RexCall（SARG范围） |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`IN`条目（SCALAR） |
| 求值逻辑 | 改写为SEARCH后由`SearchOperatorGen`展开为区间比较 |

## velox实现

velox已有内建`in`（`velox/functions/prestosql/registration/GeneralFunctionsRegistration.cpp`）。
