# PARSE_URL

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

从URL中抽取指定部分，part取值为PROTOCOL、HOST、PATH、QUERY、REF、AUTHORITY或FILE；part为QUERY且给出key时返回该查询参数的值，用于日志与来源分析。

## 用法

签名：`PARSE_URL(url, part[, key])`

| 参数 | 类型 | 说明 |
|---|---|---|
| url | STRING | 待解析的URL |
| part | STRING | 要抽取的部分，取值见上 |
| key | STRING | 可选，查询参数名，配合part为'QUERY'使用 |

返回：STRING；URL的对应部分或查询参数的值。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, PARSE_URL('http://h/p?a=1#f', 'QUERY', 'a') FROM bid;
```

输出：STRING；每行均为'1'（查询参数a的值）。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| PARSE_URL('http://h/p?a=1#f', 'QUERY', 'a') | 1 | part为'QUERY'并给出key时返回查询参数a的值 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`PARSE_URL`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`PARSE_URL`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateParserUrl`（直调`SqlFunctionUtils`的`parseUrl`） |

## velox实现

velox仓库暂无对应实现；相近的有`url_extract_host`等族（`velox/functions/prestosql/registration/URLFunctionsRegistration.cpp`）。
