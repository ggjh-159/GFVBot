# REGEXP_REPLACE

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

将s中每个匹配Java正则的子串替换为replacement，遵循java.util.regex语义，用于数字脱敏、空白归一与日志片段改写。

## 用法

签名：`REGEXP_REPLACE(s, regex, replacement)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 原字符串 |
| regex | STRING | Java正则表达式 |
| replacement | STRING | 替换文本 |

返回：STRING；完成全部替换后的字符串。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, REGEXP_REPLACE(bid.extra, '[0-9]', '#') FROM bid;
```

输出：STRING；`extra`中每个数字替换为'#'（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | REGEXP_REPLACE(extra, '[0-9]', '#') | 说明 |
|---|---|---|
| A3F19C27B4E0 | A#F##C##B#E# | 每个数字字符替换为'#' |
| 8B2D4F90A1C3 | #B#D#F##A#C# | 每个数字字符替换为'#' |
| C7E5A0D39F16 | C#E#A#D##F## | 每个数字字符替换为'#' |
| ZK9M2Q7XVBT5 | ZK#M#Q#XVBT# | 每个数字字符替换为'#' |
| D4C8B1E6A2F7 | D#C#B#E#A#F# | 每个数字字符替换为'#' |
| 5F0A9D3C7E8B | #F#A#D#C#E#B | 每个数字字符替换为'#' |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU | 不含数字，原样返回 |
| E2B7F5A9C3D0 | E#B#F#A#C#D# | 每个数字字符替换为'#' |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`REGEXP_REPLACE`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`REGEXP_REPLACE`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateRegexpReplace`（直调`SqlFunctionUtils`的`regexpReplace`） |

## velox实现

velox已有内建`regexp_replace`（`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`）。
