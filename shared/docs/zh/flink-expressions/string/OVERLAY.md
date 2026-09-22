# OVERLAY

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

将s中自1基位置n起、长m个字符的子串替换为r，用于定宽段的原位修补。m省略时默认取r的字符数。

## 用法

签名：`OVERLAY(s PLACING r FROM n [FOR m])`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 原字符串 |
| r | STRING | 用于替换的字符串 |
| n | INT | 替换起点，1基 |
| m | INT | 被替换的长度，省略时取r的字符数 |

返回：STRING；完成原位替换后的字符串。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, OVERLAY(bid.extra PLACING '**' FROM 2 FOR 2) FROM bid;
```

输出：STRING；`extra`第2到3个字符替换为'**'——每行仍是12个字符。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | OVERLAY(extra PLACING '**' FROM 2 FOR 2) | 说明 |
|---|---|---|
| A3F19C27B4E0 | A**9C27B4E0 | 第2到3个字符替换为'**'，总长不变 |
| 8B2D4F90A1C3 | 8**4F90A1C3 | 第2到3个字符替换为'**'，总长不变 |
| C7E5A0D39F16 | C**A0D39F16 | 第2到3个字符替换为'**'，总长不变 |
| ZK9M2Q7XVBT5 | Z**2Q7XVBT5 | 第2到3个字符替换为'**'，总长不变 |
| D4C8B1E6A2F7 | D**B1E6A2F7 | 第2到3个字符替换为'**'，总长不变 |
| 5F0A9D3C7E8B | 5**9D3C7E8B | 第2到3个字符替换为'**'，总长不变 |
| ZZYYXXWWVVUU | Z**XXWWVVUU | 第2到3个字符替换为'**'，总长不变 |
| E2B7F5A9C3D0 | E**F5A9C3D0 | 第2到3个字符替换为'**'，总长不变 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`OVERLAY`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`OVERLAY`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateOverlay`（直调`SqlFunctionUtils`的`overlay`） |

## velox实现

velox已有实现：sparksql套件的`overlay`（`velox/functions/sparksql/registration/RegisterString.cpp`）。
