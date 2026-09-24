# UPPER

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

将字符串s全部转换为大写，用于来源大小写混杂时在比较或分组前做大小写归一。s为NULL时返回NULL。

## 用法

签名：`UPPER(s)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING/CHAR | 待转换的字符串 |

返回：STRING；全大写结果；NULL得NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, UPPER(bid.extra) FROM bid;
```

输出：STRING；每行`extra`的12个字符转为大写（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | UPPER(extra) | 说明 |
|---|---|---|
| A3F19C27B4E0 | A3F19C27B4E0 | 输入已全为大写，结果不变 |
| 8B2D4F90A1C3 | 8B2D4F90A1C3 | 输入已全为大写，结果不变 |
| C7E5A0D39F16 | C7E5A0D39F16 | 输入已全为大写，结果不变 |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5 | 输入已全为大写，结果不变 |
| D4C8B1E6A2F7 | D4C8B1E6A2F7 | 输入已全为大写，结果不变 |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B | 输入已全为大写，结果不变 |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU | 输入已全为大写，结果不变 |
| E2B7F5A9C3D0 | E2B7F5A9C3D0 | 输入已全为大写，结果不变 |
| NULL | NULL | 输入为NULL返回NULL |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`UPPER`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`UPPER`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateUpper`（内联`BinaryStringData`的`toUpperCase`） |

## velox实现

velox已有内建`upper`（`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`）。
