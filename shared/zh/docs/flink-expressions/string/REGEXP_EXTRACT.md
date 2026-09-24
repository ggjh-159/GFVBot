# REGEXP_EXTRACT

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

抽取s中首个正则匹配的第idx个捕获组，idx为0时表示整个匹配；无匹配时返回NULL，用于从半结构化字符串中提取字段。

## 用法

签名：`REGEXP_EXTRACT(s, regex[, idx])`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 待提取的字符串 |
| regex | STRING | Java正则表达式 |
| idx | INT | 可选，捕获组编号，默认1；0表示整个匹配 |

返回：STRING；捕获组内容；无匹配得NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, REGEXP_EXTRACT(bid.extra, '([0-9A-F])', 1) FROM bid;
```

输出：STRING；首个捕获的0-9A-F字符，无匹配为NULL（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | REGEXP_EXTRACT(extra, '([0-9A-F])', 1) | 说明 |
|---|---|---|
| A3F19C27B4E0 | A | 首个匹配的0-9A-F字符 |
| 8B2D4F90A1C3 | 8 | 首个匹配的0-9A-F字符 |
| C7E5A0D39F16 | C | 首个匹配的0-9A-F字符 |
| ZK9M2Q7XVBT5 | 9 | 首个匹配的0-9A-F字符（'Z''K'不在集合内） |
| D4C8B1E6A2F7 | D | 首个匹配的0-9A-F字符 |
| 5F0A9D3C7E8B | 5 | 首个匹配的0-9A-F字符 |
| ZZYYXXWWVVUU | NULL | 无匹配字符，返回NULL |
| E2B7F5A9C3D0 | E | 首个匹配的0-9A-F字符 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`REGEXP_EXTRACT`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`REGEXP_EXTRACT`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateRegexpExtract`（直调`SqlFunctionUtils`的`regexpExtract`） |

## velox实现

GFV已在velox侧实现`regexp_extract`，注册于`velox/functions/flinksql/Register.cpp`（实现于同目录`RegexFunctions.h`）。
