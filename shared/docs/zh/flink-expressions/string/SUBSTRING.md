# SUBSTRING

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

从s的1基位置n起截取m个字符，省略m时取到串尾，是最常用的字段切片表达式。支持标准写法`SUBSTRING(s FROM n [FOR m])`与函数写法`SUBSTRING(s, n[, m])`。

## 用法

签名：`SUBSTRING(s FROM n [FOR m])`或`SUBSTRING(s, n[, m])`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 待截取的字符串 |
| n | INT | 起始位置，1基 |
| m | INT | 可选，截取长度，省略时取到串尾 |

返回：STRING；截取出的子串。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, SUBSTRING(bid.extra FROM 2 FOR 5) FROM bid;
```

输出：STRING；每行取`extra`的第2到6个字符（共5个）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | SUBSTRING(extra FROM 2 FOR 5) | 说明 |
|---|---|---|
| A3F19C27B4E0 | 3F19C | 自第2个字符起取5个字符 |
| 8B2D4F90A1C3 | B2D4F | 自第2个字符起取5个字符 |
| C7E5A0D39F16 | 7E5A0 | 自第2个字符起取5个字符 |
| ZK9M2Q7XVBT5 | K9M2Q | 自第2个字符起取5个字符 |
| D4C8B1E6A2F7 | 4C8B1 | 自第2个字符起取5个字符 |
| 5F0A9D3C7E8B | F0A9D | 自第2个字符起取5个字符 |
| ZZYYXXWWVVUU | ZYYXX | 自第2个字符起取5个字符 |
| E2B7F5A9C3D0 | 2B7F5 | 自第2个字符起取5个字符 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`SUBSTRING`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`SUBSTRING`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateSubString`（直调`BinaryStringDataUtil`的`substringSQL`） |

## velox实现

velox已有内建`substr`（`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`）（sparksql`substring`同语义）。
