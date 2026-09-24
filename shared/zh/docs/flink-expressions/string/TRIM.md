# TRIM

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

去除字符串s两端（BOTH）、开头（LEADING）或结尾（TRAILING）的指定字符c，默认去除两端的空格。

## 用法

签名：`TRIM([BOTH|LEADING|TRAILING] [c] FROM s)`

| 参数 | 类型 | 说明 |
|---|---|---|
| BOTH/LEADING/TRAILING | 关键字 | 可选，选定去除的一端，默认BOTH |
| c | STRING | 可选，待去除的字符，默认空格 |
| s | STRING | 待清理的字符串 |

返回：STRING；去除指定字符后的字符串。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, TRIM(BOTH ' ' FROM CONCAT(' ', bid.extra, ' ')) FROM bid;
```

输出：STRING；去掉人为加的空格后——每行即`extra`本身。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | TRIM(BOTH ' ' FROM CONCAT(' ', extra, ' ')) | 说明 |
|---|---|---|
| A3F19C27B4E0 | A3F19C27B4E0 | 去除首尾人为添加的空格后即extra |
| 8B2D4F90A1C3 | 8B2D4F90A1C3 | 去除首尾人为添加的空格后即extra |
| C7E5A0D39F16 | C7E5A0D39F16 | 去除首尾人为添加的空格后即extra |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5 | 去除首尾人为添加的空格后即extra |
| D4C8B1E6A2F7 | D4C8B1E6A2F7 | 去除首尾人为添加的空格后即extra |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B | 去除首尾人为添加的空格后即extra |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU | 去除首尾人为添加的空格后即extra |
| E2B7F5A9C3D0 | E2B7F5A9C3D0 | 去除首尾人为添加的空格后即extra |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`TRIM`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`TRIM`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateTrim`（直调`BinaryStringDataUtil`的`trim`） |

## velox实现

velox已有内建`trim`（`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`）。
