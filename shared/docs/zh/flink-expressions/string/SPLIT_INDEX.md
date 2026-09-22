# SPLIT_INDEX

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

按分隔符delim将字符串s切分为若干段，返回第index段（下标从0起），用于从分隔符格式的字符串中提取指定位置的子串。index越界（超出`[0, 段数-1]`）或为负数时返回NULL，不产生错误。

## 用法

签名：`SPLIT_INDEX(s, delim, index)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 待切分的字符串 |
| delim | STRING | 分隔符，按字面匹配 |
| index | INT | 段下标，0基——第一段是0 |

返回：STRING；下标越界或为负得NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, SPLIT_INDEX('a/b/c', '/', 1) FROM bid;
```

输出：STRING；每行均为'b'。

| 输入 | 输出 | 说明 |
|---|---|---|
| SPLIT_INDEX('a/b/c', '/', 1) | b | 0基下标1对应第二段 |
| SPLIT_INDEX('a/b/c', '/', 0) | a | 下标0对应第一段 |
| SPLIT_INDEX('a/b/c', '/', 3) | NULL | 越界：'a/b/c'共三段，合法下标为0/1/2 |
| SPLIT_INDEX('a/b/c', '/', -1) | NULL | 负下标返回NULL |
| SPLIT_INDEX('abc', '/', 0) | abc | 分隔符未出现时整串为一段，下标0返回整串 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`SPLIT_INDEX`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`SPLIT_INDEX`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateSplitIndex`（直调`SqlFunctionUtils`的`splitIndex`） |

## velox实现

GFV已在velox侧实现`split_index`，注册于`velox/experimental/stateful/udf/Register.cpp`（实现于同目录`SplitIndex.h`）。
