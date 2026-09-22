# CHAR_LENGTH

分类：[字符串函数](../index.md#字符串函数) · 别名：`CHARACTER_LENGTH`

## 定位与场景

统计字符串s包含的字符数（按字符计，不是字节数），用于长度校验、截断逻辑与宽度检查。空串返回0。

## 用法

签名：`CHAR_LENGTH(s)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING/CHAR | 待统计长度的字符串 |

返回：INT；字符个数；空串得0。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CHAR_LENGTH(bid.extra) FROM bid;
```

输出：INT；每行均为12（`extra`生成长度为12）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | CHAR_LENGTH(extra) | 说明 |
|---|---|---|
| A3F19C27B4E0 | 12 | 12个字符 |
| 8B2D4F90A1C3 | 12 | 12个字符 |
| C7E5A0D39F16 | 12 | 12个字符 |
| ZK9M2Q7XVBT5 | 12 | 12个字符 |
| D4C8B1E6A2F7 | 12 | 12个字符 |
| 5F0A9D3C7E8B | 12 | 12个字符 |
| ZZYYXXWWVVUU | 12 | 12个字符 |
| E2B7F5A9C3D0 | 12 | 12个字符 |
| ''（空串） | 0 | 空串返回0 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`CHAR_LENGTH`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`CHAR_LENGTH`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateCharLength`（内联`BinaryStringData`的`numChars`） |

## velox实现

velox已有内建`length`（`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`）（对varchar按字符计数）。
