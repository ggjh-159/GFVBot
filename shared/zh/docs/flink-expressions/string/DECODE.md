# DECODE

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

按指定字符集charset将字节串bytes解码为字符串，是ENCODE的逆操作，用于还原经编码传输的字节数据。

## 用法

签名：`DECODE(bytes, charset)`

| 参数 | 类型 | 说明 |
|---|---|---|
| bytes | VARBINARY | 待解码的字节串 |
| charset | STRING | 字符集名，如'utf-8' |

返回：STRING；按charset解码出的文本。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, DECODE(ENCODE(bid.extra, 'utf-8'), 'utf-8') FROM bid;
```

输出：STRING；每行还原为`extra`本身。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | DECODE(ENCODE(extra, 'utf-8'), 'utf-8') | 说明 |
|---|---|---|
| A3F19C27B4E0 | A3F19C27B4E0 | 编码再解码往返后还原为原串 |
| 8B2D4F90A1C3 | 8B2D4F90A1C3 | 编码再解码往返后还原为原串 |
| C7E5A0D39F16 | C7E5A0D39F16 | 编码再解码往返后还原为原串 |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5 | 编码再解码往返后还原为原串 |
| D4C8B1E6A2F7 | D4C8B1E6A2F7 | 编码再解码往返后还原为原串 |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B | 编码再解码往返后还原为原串 |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU | 编码再解码往返后还原为原串 |
| E2B7F5A9C3D0 | E2B7F5A9C3D0 | 编码再解码往返后还原为原串 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`DECODE`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`DECODE`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateDecode`（经`MethodCallGen`生成） |

## velox实现

velox已有内建`from_utf8`（`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`）（仅覆盖utf-8字符集）。
