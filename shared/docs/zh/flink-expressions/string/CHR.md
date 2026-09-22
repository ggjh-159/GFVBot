# CHR

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

按Unicode码点n生成对应的单字符字符串，用于由数字构造控制字符或展示字符。

## 用法

签名：`CHR(n)`

| 参数 | 类型 | 说明 |
|---|---|---|
| n | INT | Unicode码点 |

返回：STRING；码点对应的单字符。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CHR(65) FROM bid;
```

输出：STRING；每行均为'A'。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| CHR(65) | A | 码点65对应字符'A' |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`CHR`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`CHR`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateChr`（直调`SqlFunctionUtils`的`chr`） |

## velox实现

velox已有内建`chr`（`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`）。
