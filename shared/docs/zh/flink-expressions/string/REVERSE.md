# REVERSE

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

将字符串s的字符顺序反转，用于回文检查与字节级调试。

## 用法

签名：`REVERSE(s)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 待反转的字符串 |

返回：STRING；字符顺序反转后的字符串。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, REVERSE(bid.extra) FROM bid;
```

输出：STRING；`extra`反转——每行12个字符。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | REVERSE(extra) | 说明 |
|---|---|---|
| A3F19C27B4E0 | 0E4B72C91F3A | 12个字符逆序排列 |
| 8B2D4F90A1C3 | 3C1A09F4D2B8 | 12个字符逆序排列 |
| C7E5A0D39F16 | 61F93D0A5E7C | 12个字符逆序排列 |
| ZK9M2Q7XVBT5 | 5TBVX7Q2M9KZ | 12个字符逆序排列 |
| D4C8B1E6A2F7 | 7F2A6E1B8C4D | 12个字符逆序排列 |
| 5F0A9D3C7E8B | B8E7C3D9A0F5 | 12个字符逆序排列 |
| ZZYYXXWWVVUU | UUVVWWXXYYZZ | 12个字符逆序排列 |
| E2B7F5A9C3D0 | 0D3C9A5F7B2E | 12个字符逆序排列 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`REVERSE`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`REVERSE`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateReverse`（直调`BinaryStringDataUtil`的`reverse`） |

## velox实现

velox已有内建`reverse`（`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`）。
