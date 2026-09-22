# LEFT

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

返回字符串s最前的n个字符，用于区号、类目编码等前缀的轻量提取。

## 用法

签名：`LEFT(s, n)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 待截取的字符串 |
| n | INT | 截取的字符数 |

返回：STRING；s的前n个字符。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, LEFT(bid.extra, 4) FROM bid;
```

输出：STRING；每行取`extra`的前4个字符。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | LEFT(extra, 4) | 说明 |
|---|---|---|
| A3F19C27B4E0 | A3F1 | 取前4个字符 |
| 8B2D4F90A1C3 | 8B2D | 取前4个字符 |
| C7E5A0D39F16 | C7E5 | 取前4个字符 |
| ZK9M2Q7XVBT5 | ZK9M | 取前4个字符 |
| D4C8B1E6A2F7 | D4C8 | 取前4个字符 |
| 5F0A9D3C7E8B | 5F0A | 取前4个字符 |
| ZZYYXXWWVVUU | ZZYY | 取前4个字符 |
| E2B7F5A9C3D0 | E2B7 | 取前4个字符 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`LEFT`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`LEFT`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateLeft`（内联生成子串截取） |

## velox实现

velox已有实现：sparksql套件的`left`（`velox/functions/sparksql/registration/RegisterString.cpp`）。
