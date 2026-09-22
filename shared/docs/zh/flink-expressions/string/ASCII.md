# ASCII

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

返回字符串s首字符的数字编码，用于查看首字符的编码值以做路由或校验。s为空串时返回0。

## 用法

签名：`ASCII(s)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 待取首字符编码的字符串 |

返回：INT；首字符的数字编码；空串得0。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ASCII(bid.extra) FROM bid;
```

输出：INT；`extra`首字符的编码（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | ASCII(extra) | 说明 |
|---|---|---|
| A3F19C27B4E0 | 65 | 首字符'A'的编码 |
| 8B2D4F90A1C3 | 56 | 首字符'8'的编码 |
| C7E5A0D39F16 | 67 | 首字符'C'的编码 |
| ZK9M2Q7XVBT5 | 90 | 首字符'Z'的编码 |
| D4C8B1E6A2F7 | 68 | 首字符'D'的编码 |
| 5F0A9D3C7E8B | 53 | 首字符'5'的编码 |
| ZZYYXXWWVVUU | 90 | 首字符'Z'的编码 |
| E2B7F5A9C3D0 | 69 | 首字符'E'的编码 |
| ''（空串） | 0 | 空串返回0 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`ASCII`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`ASCII`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateAscii`（内联`BinaryStringData`的`byteAt`） |

## velox实现

velox已有实现：sparksql套件的`ascii`（`velox/functions/sparksql/registration/RegisterString.cpp`）。
