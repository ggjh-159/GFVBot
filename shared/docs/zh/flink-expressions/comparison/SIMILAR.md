# SIMILAR

分类：[比较函数](../index.md#比较函数) · 别名：`SIMILAR TO`

## 定位与场景

经`s SIMILAR TO pattern`按SQL:1999正则匹配——其语法（字符类、基于%和_的量词）既不同于LIKE通配符也不同于Java正则。需要比LIKE更强的模式表达能力时使用。

## 用法

签名：`s SIMILAR TO pattern`——s为被检字符串，pattern为SQL:1999正则。

返回：BOOLEAN；s与pattern匹配为TRUE，否则为FALSE。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.extra SIMILAR TO '%[0-9A-F]%' FROM bid;
```

输出：BOOLEAN；`extra`至少含一个0-9A-F字符时为true（随行数据变化）。

示例（16行源的前8行，示意数据，末行补空值边界；前列为输入列，末两列为该行结果与说明）：

| extra | extra SIMILAR TO '%[0-9A-F]%' | 说明 |
|---|---|---|
| A3F19C27B4E0 | TRUE | 含字符类`[0-9A-F]`内字符 |
| 8B2D4F90A1C3 | TRUE | 含数字字符 |
| C7E5A0D39F16 | TRUE | 含数字字符 |
| ZK9M2Q7XVBT5 | TRUE | 含数字9、2、7、5 |
| D4C8B1E6A2F7 | TRUE | 含数字字符 |
| 5F0A9D3C7E8B | TRUE | 含数字字符 |
| ZZYYXXWWVVUU | FALSE | 不含0-9A-F内任何字符 |
| E2B7F5A9C3D0 | TRUE | 含数字字符 |
| NULL | UNKNOWN | 任一侧为NULL得UNKNOWN |

## 源码位置

GFV实现该表达式的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配`BuiltInFunctionDefinitions`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`SIMILAR`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateSimilarTo` |

## velox实现

velox仓库暂无对应实现。
