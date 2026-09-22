# ENCODE

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

按指定字符集charset将字符串s编码为字节串，用于为字节级函数准备输入。

## 用法

签名：`ENCODE(s, charset)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 待编码的字符串 |
| charset | STRING | 字符集名，如'utf-8' |

返回：VARBINARY；按charset编码得到的字节串。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ENCODE(bid.extra, 'utf-8') FROM bid;
```

输出：VARBINARY；每行`extra`的12个UTF-8字节。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果；输出列为字节串的十六进制表示）：

| extra | ENCODE(extra, 'utf-8') | 说明 |
|---|---|---|
| A3F19C27B4E0 | 413346313943323742344530 | 12个ASCII字符的UTF-8字节，每个占1字节 |
| 8B2D4F90A1C3 | 384232443446393041314333 | 12个ASCII字符的UTF-8字节，每个占1字节 |
| C7E5A0D39F16 | 433745354130443339463136 | 12个ASCII字符的UTF-8字节，每个占1字节 |
| ZK9M2Q7XVBT5 | 5A4B394D3251375856425435 | 12个ASCII字符的UTF-8字节，每个占1字节 |
| D4C8B1E6A2F7 | 443443384231453641324637 | 12个ASCII字符的UTF-8字节，每个占1字节 |
| 5F0A9D3C7E8B | 354630413944334337453842 | 12个ASCII字符的UTF-8字节，每个占1字节 |
| ZZYYXXWWVVUU | 5A5A59595858575756565555 | 12个ASCII字符的UTF-8字节，每个占1字节 |
| E2B7F5A9C3D0 | 453242374635413943334430 | 12个ASCII字符的UTF-8字节，每个占1字节 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`ENCODE`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`ENCODE`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateEncode`（经`MethodCallGen`生成） |

## velox实现

velox已有内建`to_utf8`（`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`）（仅覆盖utf-8字符集）。
