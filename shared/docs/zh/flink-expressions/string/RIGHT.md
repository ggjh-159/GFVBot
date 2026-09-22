# RIGHT

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

返回字符串s最后的n个字符，用于文件扩展名、结尾标记等后缀提取。

## 用法

签名：`RIGHT(s, n)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 待截取的字符串 |
| n | INT | 截取的字符数 |

返回：STRING；s的最后n个字符。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, RIGHT(bid.extra, 4) FROM bid;
```

输出：STRING；每行取`extra`的最后4个字符。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | RIGHT(extra, 4) | 说明 |
|---|---|---|
| A3F19C27B4E0 | B4E0 | 取最后4个字符 |
| 8B2D4F90A1C3 | A1C3 | 取最后4个字符 |
| C7E5A0D39F16 | 9F16 | 取最后4个字符 |
| ZK9M2Q7XVBT5 | VBT5 | 取最后4个字符 |
| D4C8B1E6A2F7 | A2F7 | 取最后4个字符 |
| 5F0A9D3C7E8B | 7E8B | 取最后4个字符 |
| ZZYYXXWWVVUU | VVUU | 取最后4个字符 |
| E2B7F5A9C3D0 | C3D0 | 取最后4个字符 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`RIGHT`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`RIGHT`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateRight`（内联生成子串截取） |

## velox实现

velox仓库暂无对应实现。
