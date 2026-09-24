# REPEAT

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

将字符串s重复n次后返回，用于构造分隔串与测试中的期望模式。

## 用法

签名：`REPEAT(s, n)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 待重复的字符串 |
| n | INT | 重复次数 |

返回：STRING；s重复n次的结果。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, REPEAT(bid.extra, 2) FROM bid;
```

输出：STRING；`extra`重复两遍——每行24个字符。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | REPEAT(extra, 2) | 说明 |
|---|---|---|
| A3F19C27B4E0 | A3F19C27B4E0A3F19C27B4E0 | extra重复两遍，共24个字符 |
| 8B2D4F90A1C3 | 8B2D4F90A1C38B2D4F90A1C3 | extra重复两遍，共24个字符 |
| C7E5A0D39F16 | C7E5A0D39F16C7E5A0D39F16 | extra重复两遍，共24个字符 |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5ZK9M2Q7XVBT5 | extra重复两遍，共24个字符 |
| D4C8B1E6A2F7 | D4C8B1E6A2F7D4C8B1E6A2F7 | extra重复两遍，共24个字符 |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B5F0A9D3C7E8B | extra重复两遍，共24个字符 |
| ZZYYXXWWVVUU | ZZYYXXWWVVUUZZYYXXWWVVUU | extra重复两遍，共24个字符 |
| E2B7F5A9C3D0 | E2B7F5A9C3D0E2B7F5A9C3D0 | extra重复两遍，共24个字符 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`REPEAT`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`REPEAT`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateRepeat`（直调`SqlFunctionUtils`的`repeat`） |

## velox实现

velox已有实现：sparksql套件的`repeat`（`velox/functions/sparksql/registration/RegisterString.cpp`）。
