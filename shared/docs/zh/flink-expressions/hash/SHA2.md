# SHA2

分类：[哈希函数](../index.md#哈希函数) · 别名：—

## 定位与场景

按指定长度取SHA-2摘要——hashLength为224、256、384或512；0视同256；其他长度会被拒绝。一个拼写覆盖整个SHA-2系列。

## 用法

签名：`SHA2(s, hashLength)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 待摘要的字符串 |
| hashLength | INT | 摘要位数：224、256、384或512；0视同256；其他长度被拒绝 |

返回：STRING；摘要位数与hashLength一致，渲染为hashLength/4个小写十六进制字符。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, SHA2(bid.extra, 256) FROM bid;
```

输出：STRING；此处为64个十六进制字符（hashLength 256），随行数据变化。

示例（16行源的前8行，示意数据；前列为输入列，末两列为该行结果与说明）：

| extra | SHA2(extra, 256) | 说明 |
|---|---|---|
| A3F19C27B4E0 | 1683ce8b4f10d5996920d6b50c283e370b1f2d36bc310f7501707b190ebf4b90 | 256位摘要，64个小写十六进制字符 |
| 8B2D4F90A1C3 | c8a6c2f6832233aa17dc4c298bee7d59e1bf364e839a7a2ade38175050edaf6d | 256位摘要，64个小写十六进制字符 |
| C7E5A0D39F16 | b7bace464a3ce0a07adde2f4cacacf195a4073cddcc696d737b0f81da6071bf2 | 256位摘要，64个小写十六进制字符 |
| ZK9M2Q7XVBT5 | 59b80c6d05771d1c3c76a5a84c9385a97f096a3eae570d2ff7656a8ad6e5f15f | 256位摘要，64个小写十六进制字符 |
| D4C8B1E6A2F7 | 66d61b03455e9813b1f24a4e7470f70c18503ea19196d5c7a12c58807129938d | 256位摘要，64个小写十六进制字符 |
| 5F0A9D3C7E8B | 409a801df9ae867309af325c178a3b4b01cd61dd9fcce693f780a56be5e4bbfe | 256位摘要，64个小写十六进制字符 |
| ZZYYXXWWVVUU | 0e551d54c4146296d8d20bd28227c628489301a07c4a60b2c8f90e980f9661ec | 256位摘要，64个小写十六进制字符 |
| E2B7F5A9C3D0 | f914a5388bc952a6a1ee6878c814f50971742cda3bb1e5922deaecc5c7f5e3e3 | 256位摘要，64个小写十六进制字符 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`SHA2`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`SHA2`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateSha2`（直调`SqlFunctionUtils`的`hash`，算法按hashLength选择） |

## velox实现

velox已有实现：sparksql套件的`sha2`（`velox/functions/sparksql/registration/RegisterBinary.cpp`）。
