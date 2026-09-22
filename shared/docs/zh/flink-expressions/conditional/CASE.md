# CASE

分类：[条件函数](../index.md#条件函数) · 别名：—

## 定位与场景

分支选择表达式：自上而下求值各WHEN条件，返回第一个求值为TRUE的分支的值；均不满足时返回ELSE值，省略ELSE则返回NULL。搜索形式`CASE WHEN cond THEN val ... END`按条件选择分支；简单形式`CASE expr WHEN v THEN val ... END`将expr依次与各v做等值比较。条件求值遵循三值逻辑：结果为UNKNOWN时视同不满足，继续考察下一分支——判断空值因此必须使用`IS NULL`；`expr = NULL`的求值结果恒为UNKNOWN，不会命中任何分支。

## 用法

语法：`CASE WHEN cond THEN v [WHEN ...] [ELSE v] END`（搜索形式）或`CASE expr WHEN v THEN r [WHEN ...] [ELSE r] END`（简单形式）——各分支结果须统一为同一类型。

| 组成 | 说明 |
|---|---|
| WHEN cond / WHEN v | 自上而下求值，首个为TRUE的分支生效，其后分支不再求值 |
| THEN v / THEN r | 所属分支生效时返回的值 |
| ELSE v | 所有分支均不满足时返回的值；省略则返回NULL |

返回：生效分支的值；类型为各分支结果的公共类型。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CASE WHEN bid.auction > 10 THEN 'high' ELSE 'low' END FROM bid;
```

输出：STRING；`auction > 10`时为'high'，否则'low'（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | CASE WHEN auction > 10 THEN 'high' ELSE 'low' END |
|---|---|
| 3 | low |
| 19 | high |
| 8 | low |
| 1 | low |
| 14 | high |
| 7 | low |
| 11 | high |
| 20 | high |

## 源码位置

GFV实现该表达式的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配`BuiltInFunctionDefinitions`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`IF`条目（SCALAR） |
| 求值逻辑 | `ScalarOperatorGens`内联生成的多分支if/else |

## velox实现

velox表达式内核将其作为特型`if`/`switch`处理（`velox/expression/RegisterSpecialForm.cpp`），无独立函数注册。
