# REPLACE

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

将s中每次出现的search替换为replacement，按字面匹配而非正则，无需任何转义。

## 用法

签名：`REPLACE(s, search, replacement)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 原字符串 |
| search | STRING | 待替换的字面子串 |
| replacement | STRING | 替换文本 |

返回：STRING；完成全部替换后的字符串。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, REPLACE(bid.extra, 'A', 'a') FROM bid;
```

输出：STRING；`extra`中每个'A'换成'a'（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | REPLACE(extra, 'A', 'a') | 说明 |
|---|---|---|
| A3F19C27B4E0 | a3F19C27B4E0 | 每个'A'替换为'a' |
| 8B2D4F90A1C3 | 8B2D4F90a1C3 | 每个'A'替换为'a' |
| C7E5A0D39F16 | C7E5a0D39F16 | 每个'A'替换为'a' |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5 | 串中不含'A'，原样返回 |
| D4C8B1E6A2F7 | D4C8B1E6a2F7 | 每个'A'替换为'a' |
| 5F0A9D3C7E8B | 5F0a9D3C7E8B | 每个'A'替换为'a' |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU | 串中不含'A'，原样返回 |
| E2B7F5A9C3D0 | E2B7F5a9C3D0 | 每个'A'替换为'a' |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`REPLACE`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`REPLACE`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateReplace`（直调`SqlFunctionUtils`的`replace`） |

## velox实现

velox已有内建`replace`（`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`）。
