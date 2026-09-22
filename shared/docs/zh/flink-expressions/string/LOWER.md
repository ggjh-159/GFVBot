# LOWER

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

将字符串s全部转换为小写，用于JOIN或去重前对标识符与键做大小写规范化。s为NULL时返回NULL。

## 用法

签名：`LOWER(s)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING/CHAR | 待转换的字符串 |

返回：STRING；全小写结果；NULL得NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, LOWER(bid.extra) FROM bid;
```

输出：STRING；每行`extra`的12个字符转为小写（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | LOWER(extra) | 说明 |
|---|---|---|
| A3F19C27B4E0 | a3f19c27b4e0 | 字母全部转为小写 |
| 8B2D4F90A1C3 | 8b2d4f90a1c3 | 字母全部转为小写 |
| C7E5A0D39F16 | c7e5a0d39f16 | 字母全部转为小写 |
| ZK9M2Q7XVBT5 | zk9m2q7xvbt5 | 字母全部转为小写 |
| D4C8B1E6A2F7 | d4c8b1e6a2f7 | 字母全部转为小写 |
| 5F0A9D3C7E8B | 5f0a9d3c7e8b | 字母全部转为小写 |
| ZZYYXXWWVVUU | zzyyxxwwvvuu | 字母全部转为小写 |
| E2B7F5A9C3D0 | e2b7f5a9c3d0 | 字母全部转为小写 |
| NULL | NULL | 输入为NULL返回NULL |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`LOWER`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`LOWER`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateLower`（内联`BinaryStringData`的`toLowerCase`） |

## velox实现

velox已有内建`lower`（`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`）。
