# SHA1

分类：[哈希函数](../index.md#哈希函数) · 别名：—

## 定位与场景

160位SHA-1摘要，40个小写十六进制字符。传统指纹用途——安全相关场景请改用SHA-2系列。

## 用法

签名：`SHA1(s)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 待摘要的字符串 |

返回：STRING；40个小写十六进制字符。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, SHA1(bid.extra) FROM bid;
```

输出：STRING；每行40个十六进制字符（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末两列为该行结果与说明）：

| extra | SHA1(extra) | 说明 |
|---|---|---|
| A3F19C27B4E0 | 44efb9590ae04716b158b17ebdaf9e6bfa5c5dab | 160位摘要，40个小写十六进制字符 |
| 8B2D4F90A1C3 | 3fde48eac4ceff69c20a7c0daa0467e1eba4ad1f | 160位摘要，40个小写十六进制字符 |
| C7E5A0D39F16 | ae380e5be7cdd061963e6791bfa6968732657283 | 160位摘要，40个小写十六进制字符 |
| ZK9M2Q7XVBT5 | c725c42b953ede1222cf7090f2f8bf1676e08fe4 | 160位摘要，40个小写十六进制字符 |
| D4C8B1E6A2F7 | 12e227e4a5a9248aa8a94cbc89efa07e7f2e1ab2 | 160位摘要，40个小写十六进制字符 |
| 5F0A9D3C7E8B | 7ca21ce9fbfd9c1b6e46f245b1f3541b8aa66180 | 160位摘要，40个小写十六进制字符 |
| ZZYYXXWWVVUU | 503c53179981a96e0fa7a9c21bb00c9169fdea35 | 160位摘要，40个小写十六进制字符 |
| E2B7F5A9C3D0 | 27d75fb52e892e24ee936a61ce4fee4bf5e17491 | 160位摘要，40个小写十六进制字符 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`SHA1`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`SHA1`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateSha1`（直调`SqlFunctionUtils`的`hash`，算法名内联） |

## velox实现

velox已有内建`sha1`（`velox/functions/prestosql/registration/BinaryFunctionsRegistration.cpp`）。
