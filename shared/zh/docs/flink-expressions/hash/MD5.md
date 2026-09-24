# MD5

分类：[哈希函数](../index.md#哈希函数) · 别名：—

## 定位与场景

字符串的128位MD5摘要，渲染为32个小写十六进制字符。用于变更检测、缓存键、指纹——其抗碰撞性不足以用于安全场景。

## 用法

签名：`MD5(s)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 待摘要的字符串 |

返回：STRING；32个小写十六进制字符。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, MD5(bid.extra) FROM bid;
```

输出：STRING；每行32个十六进制字符（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末两列为该行结果与说明）：

| extra | MD5(extra) | 说明 |
|---|---|---|
| A3F19C27B4E0 | 3391d976e274ac3c8b3987f29f4cfd90 | 128位摘要，32个小写十六进制字符 |
| 8B2D4F90A1C3 | d2700e68ec3f4bf6ab516f28083fb04a | 128位摘要，32个小写十六进制字符 |
| C7E5A0D39F16 | ffd94a91f55bebe588985be25c3d3edd | 128位摘要，32个小写十六进制字符 |
| ZK9M2Q7XVBT5 | acba1453a0ecdcdeb60e6cd1ddd0f70d | 128位摘要，32个小写十六进制字符 |
| D4C8B1E6A2F7 | 05c4ad9174cc98f55266ab0883c337b1 | 128位摘要，32个小写十六进制字符 |
| 5F0A9D3C7E8B | 7aa3ea2eba7a655fea2c8e2610af726e | 128位摘要，32个小写十六进制字符 |
| ZZYYXXWWVVUU | 83fd3f4384f97d588a344e76e0940f03 | 128位摘要，32个小写十六进制字符 |
| E2B7F5A9C3D0 | af8edb2fd39e82bc68428cb9d71ef95f | 128位摘要，32个小写十六进制字符 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`MD5`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`MD5`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateMd5`（直调`SqlFunctionUtils`的`hash`，算法名内联） |

## velox实现

velox已有内建`md5`（`velox/functions/prestosql/registration/BinaryFunctionsRegistration.cpp`）。
