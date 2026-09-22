# REGEXP

分类：[字符串函数](../index.md#字符串函数) · 别名：`RLIKE`

## 定位与场景

按Java正则语义判断pattern是否与s全串匹配，返回布尔结果。必须以函数形式`REGEXP(s, pattern)`调用——中缀写法`a REGEXP b`会被Flink 1.19解析器拒绝。

## 用法

签名：`REGEXP(s, pattern)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 待匹配的字符串 |
| pattern | STRING | Java正则表达式 |

返回：BOOLEAN；pattern是否与s全串匹配。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, REGEXP(bid.extra, '^[0-9A-F]+$') FROM bid;
```

输出：BOOLEAN；`extra`仅由0-9A-F字符组成时为true（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | REGEXP(extra, '^[0-9A-F]+$') | 说明 |
|---|---|---|
| A3F19C27B4E0 | TRUE | 全部字符落在0-9A-F集合内 |
| 8B2D4F90A1C3 | TRUE | 全部字符落在0-9A-F集合内 |
| C7E5A0D39F16 | TRUE | 全部字符落在0-9A-F集合内 |
| ZK9M2Q7XVBT5 | FALSE | 含Z、K等集合外字符 |
| D4C8B1E6A2F7 | TRUE | 全部字符落在0-9A-F集合内 |
| 5F0A9D3C7E8B | TRUE | 全部字符落在0-9A-F集合内 |
| ZZYYXXWWVVUU | FALSE | 含Z、Y等集合外字符 |
| E2B7F5A9C3D0 | TRUE | 全部字符落在0-9A-F集合内 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`REGEXP`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`REGEXP`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateRegExp`（直调`SqlFunctionUtils`的`regExp`） |

## velox实现

velox已有内建`regexp_like`（`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`）（velox版为部分匹配，Flink要求全串匹配；sparksql套件注册`rlike`）。
