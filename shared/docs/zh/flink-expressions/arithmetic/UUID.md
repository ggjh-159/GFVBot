# UUID

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

每次调用生成一个新的RFC 4122 type-4（随机）UUID字符串，为非确定函数；用于合成键与请求id。

## 用法

签名：`UUID()`

无参数。

返回：STRING；36字符的UUID文本，非确定。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, UUID() FROM bid;
```

输出：STRING；每行一个新的36字符UUID（非确定）。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| — | 3f8a2c1e-9b4d-4c6a-8e2f-1a5b9d0c7e3a | 一次调用的示例值，不可复现 |

输出每行重新生成（非确定），此处展示一次抽取的值。

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`UUID`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`UUID`条目（SCALAR） |
| 求值逻辑 | 经`StringCallGen`的UUID分支内联`java.util.UUID.randomUUID()`调用 |

## velox实现

velox已有内建`uuid`（`velox/functions/prestosql/UuidFunctions.h`；返回UUID类型而非字符串）。
