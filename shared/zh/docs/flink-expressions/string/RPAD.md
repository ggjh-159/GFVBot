# RPAD

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

用pad在s右侧补齐至恰好len个字符；s超过len个字符时结果截断为len个字符。用于格式化定宽编码与展示列。

## 用法

签名：`RPAD(s, len, pad)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 原字符串 |
| len | INT | 结果宽度 |
| pad | STRING | 补齐用的字符串 |

返回：STRING；宽度为len的结果；超长输入截到len。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, RPAD(bid.extra, 15, '*') FROM bid;
```

输出：STRING；宽度15——每行在`extra`后补3个'*'。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | RPAD(extra, 15, '*') | 说明 |
|---|---|---|
| A3F19C27B4E0 | A3F19C27B4E0*** | 右侧补3个'*'补齐到宽度15 |
| 8B2D4F90A1C3 | 8B2D4F90A1C3*** | 右侧补3个'*'补齐到宽度15 |
| C7E5A0D39F16 | C7E5A0D39F16*** | 右侧补3个'*'补齐到宽度15 |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5*** | 右侧补3个'*'补齐到宽度15 |
| D4C8B1E6A2F7 | D4C8B1E6A2F7*** | 右侧补3个'*'补齐到宽度15 |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B*** | 右侧补3个'*'补齐到宽度15 |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU*** | 右侧补3个'*'补齐到宽度15 |
| E2B7F5A9C3D0 | E2B7F5A9C3D0*** | 右侧补3个'*'补齐到宽度15 |
| abcdefghijklmnopqrst（示意，20字符） | abcdefghijklmno | 输入超过len时截断为前len=15个字符 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`RPAD`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`RPAD`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateRpad`（直调`SqlFunctionUtils`的`rpad`） |

## velox实现

velox已有内建`rpad`（`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`）。
