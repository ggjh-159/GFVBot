# STR_TO_MAP

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

以pairDelim分隔键值对、kvDelim分隔键与值，将s解析为MAP<STRING, STRING>，用于把序列化的标签串或参数串还原为可查询的map。

## 用法

签名：`STR_TO_MAP(s[, pairDelim[, kvDelim]])`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 待解析的字符串 |
| pairDelim | STRING | 可选，键值对之间的分隔符 |
| kvDelim | STRING | 可选，键与值之间的分隔符 |

返回：MAP<STRING, STRING>；解析得到的映射。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, STR_TO_MAP('a=1,b=2', ',', '=') FROM bid;
```

输出：MAP<STRING, STRING>；每行均为{a=1, b=2}。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| STR_TO_MAP('a=1,b=2', ',', '=') | {a=1, b=2} | 以','分隔键值对、'='分隔键与值 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`STR_TO_MAP`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`STR_TO_MAP`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateStrToMap`（直调`SqlFunctionUtils`的`strToMap`） |

## velox实现

velox已有实现：sparksql套件的`str_to_map`（`velox/functions/sparksql/registration/RegisterString.cpp`）。
