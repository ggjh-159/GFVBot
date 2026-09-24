# CONCAT

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

将两个及以上字符串参数从左到右拼接为一个字符串，用于拼装展示字符串与复合键。任一参数为NULL时整体返回NULL。

## 用法

签名：`CONCAT(s1, s2, ...)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s1, s2, ... | STRING | 待拼接的字符串，两个及以上 |

返回：STRING；各参数按顺序拼接的结果；任一参数为NULL得NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CONCAT(bid.extra, '-suffix') FROM bid;
```

输出：STRING；`extra`加上字面量'-suffix'——每行19个字符。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | CONCAT(extra, '-suffix') | 说明 |
|---|---|---|
| A3F19C27B4E0 | A3F19C27B4E0-suffix | extra与字面量拼接，共19个字符 |
| 8B2D4F90A1C3 | 8B2D4F90A1C3-suffix | extra与字面量拼接，共19个字符 |
| C7E5A0D39F16 | C7E5A0D39F16-suffix | extra与字面量拼接，共19个字符 |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5-suffix | extra与字面量拼接，共19个字符 |
| D4C8B1E6A2F7 | D4C8B1E6A2F7-suffix | extra与字面量拼接，共19个字符 |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B-suffix | extra与字面量拼接，共19个字符 |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU-suffix | extra与字面量拼接，共19个字符 |
| E2B7F5A9C3D0 | E2B7F5A9C3D0-suffix | extra与字面量拼接，共19个字符 |
| NULL | NULL | 任一参数为NULL时结果为NULL |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`CONCAT_FUNCTION`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`CONCAT`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateConcat`（直调`BinaryStringDataUtil`的`concat`） |

## velox实现

velox已有内建`concat`（`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`）。
