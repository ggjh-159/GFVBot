# FROM_BASE64

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

将base64文本s解码还原为原字符串，是TO_BASE64的逆操作。

## 用法

签名：`FROM_BASE64(s)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | base64编码的文本 |

返回：STRING；解码还原的原字符串。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, FROM_BASE64(TO_BASE64(bid.extra)) FROM bid;
```

输出：STRING；每行还原为`extra`本身。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | FROM_BASE64(TO_BASE64(extra)) | 说明 |
|---|---|---|
| A3F19C27B4E0 | A3F19C27B4E0 | base64编解码往返后还原为原串 |
| 8B2D4F90A1C3 | 8B2D4F90A1C3 | base64编解码往返后还原为原串 |
| C7E5A0D39F16 | C7E5A0D39F16 | base64编解码往返后还原为原串 |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5 | base64编解码往返后还原为原串 |
| D4C8B1E6A2F7 | D4C8B1E6A2F7 | base64编解码往返后还原为原串 |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B | base64编解码往返后还原为原串 |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU | base64编解码往返后还原为原串 |
| E2B7F5A9C3D0 | E2B7F5A9C3D0 | base64编解码往返后还原为原串 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`FROM_BASE64`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`FROM_BASE64`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateFromBase64`（直调`SqlFunctionUtils`的`fromBase64`） |

## velox实现

velox已有内建`from_base64`（`velox/functions/prestosql/registration/BinaryFunctionsRegistration.cpp`）。
