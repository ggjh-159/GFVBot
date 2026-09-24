# TO_BASE64

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

将字符串s编码为base64文本，使字节内容可安全通过文本通道传输。

## 用法

签名：`TO_BASE64(s)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 待编码的字符串 |

返回：STRING；base64编码文本。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, TO_BASE64(bid.extra) FROM bid;
```

输出：STRING；`extra`的12字节base64——每行16个字符。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | TO_BASE64(extra) | 说明 |
|---|---|---|
| A3F19C27B4E0 | QTNGMTlDMjdCNEUw | 12字节编码为16个base64字符 |
| 8B2D4F90A1C3 | OEIyRDRGOTBBMUMz | 12字节编码为16个base64字符 |
| C7E5A0D39F16 | QzdFNUEwRDM5RjE2 | 12字节编码为16个base64字符 |
| ZK9M2Q7XVBT5 | Wks5TTJRN1hWQlQ1 | 12字节编码为16个base64字符 |
| D4C8B1E6A2F7 | RDRDOEIxRTZBMkY3 | 12字节编码为16个base64字符 |
| 5F0A9D3C7E8B | NUYwQTlEM0M3RThC | 12字节编码为16个base64字符 |
| ZZYYXXWWVVUU | WlpZWVhYV1dWVlVV | 12字节编码为16个base64字符 |
| E2B7F5A9C3D0 | RTJCN0Y1QTlDM0Qw | 12字节编码为16个base64字符 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`TO_BASE64`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`TO_BASE64`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateToBase64`（直调`SqlFunctionUtils`的`toBase64`） |

## velox实现

velox已有内建`to_base64`（`velox/functions/prestosql/registration/BinaryFunctionsRegistration.cpp`）。
