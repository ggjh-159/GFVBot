# INSTR

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

返回sub在s中首次出现的位置（1基），不存在时返回0，用于定位子串。语义与POSITION一致，但采用Oracle风格的参数顺序`INSTR(s, sub)`，便于移植Oracle SQL。

## 用法

签名：`INSTR(s, sub)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 被查找的字符串 |
| sub | STRING | 待定位的子串 |

返回：INT；首次出现位置，1基；不存在得0。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, INSTR(bid.extra, 'A') FROM bid;
```

输出：INT；`extra`中首个'A'的下标，不存在则为0（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | INSTR(extra, 'A') | 说明 |
|---|---|---|
| A3F19C27B4E0 | 1 | 首个'A'位于第1个字符 |
| 8B2D4F90A1C3 | 9 | 首个'A'位于第9个字符 |
| C7E5A0D39F16 | 5 | 首个'A'位于第5个字符 |
| ZK9M2Q7XVBT5 | 0 | 串中不含'A'，返回0 |
| D4C8B1E6A2F7 | 9 | 首个'A'位于第9个字符 |
| 5F0A9D3C7E8B | 4 | 首个'A'位于第4个字符 |
| ZZYYXXWWVVUU | 0 | 串中不含'A'，返回0 |
| E2B7F5A9C3D0 | 7 | 首个'A'位于第7个字符 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`INSTR`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`INSTR`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateInstr`（直调`SqlFunctionUtils`的`instr`） |

## velox实现

velox已有实现：sparksql套件的`instr`（`velox/functions/sparksql/registration/RegisterString.cpp`）。
