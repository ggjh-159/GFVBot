# CONCAT_WS

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

以分隔符sep连接其余字符串参数，用于生成'a,b,c'形式的可读列表。NULL参数被跳过而不产生空位；仅当分隔符sep为NULL时返回NULL。

## 用法

签名：`CONCAT_WS(sep, s1, s2, ...)`

| 参数 | 类型 | 说明 |
|---|---|---|
| sep | STRING | 连接用的分隔符，位于参数表最前 |
| s1, s2, ... | STRING | 待连接的字符串，两个及以上 |

返回：STRING；以sep连接各非NULL参数；sep为NULL得NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CONCAT_WS('-', bid.extra, 'x') FROM bid;
```

输出：STRING；每行为`<extra>-x`。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | CONCAT_WS('-', extra, 'x') | 说明 |
|---|---|---|
| A3F19C27B4E0 | A3F19C27B4E0-x | extra与'x'以'-'连接 |
| 8B2D4F90A1C3 | 8B2D4F90A1C3-x | extra与'x'以'-'连接 |
| C7E5A0D39F16 | C7E5A0D39F16-x | extra与'x'以'-'连接 |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5-x | extra与'x'以'-'连接 |
| D4C8B1E6A2F7 | D4C8B1E6A2F7-x | extra与'x'以'-'连接 |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B-x | extra与'x'以'-'连接 |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU-x | extra与'x'以'-'连接 |
| E2B7F5A9C3D0 | E2B7F5A9C3D0-x | extra与'x'以'-'连接 |
| NULL | x | NULL参数被跳过，仅剩字面量'x' |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`CONCAT_WS`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`CONCAT_WS`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateConcatWs`（直调`BinaryStringDataUtil`的`concatWs`） |

## velox实现

velox已有实现：sparksql套件的`concat_ws`（`velox/functions/sparksql/registration/RegisterString.cpp`）。
