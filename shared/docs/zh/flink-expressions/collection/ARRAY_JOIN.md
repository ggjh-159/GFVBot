# ARRAY_JOIN

分类：[集合函数](../index.md#集合函数) · 别名：—

## 定位与场景

用分隔符把数组元素连接为一个字符串。NULL元素默认被跳过，给出nullReplacement时以该值代替参与连接；数组本身为NULL得NULL。用于把标签列表渲染成可读或类CSV的输出。

## 用法

签名：`ARRAY_JOIN(arr, delimiter[, nullReplacement])`

| 参数 | 类型 | 说明 |
|---|---|---|
| arr | ARRAY<T> | 待连接的数组 |
| delimiter | STRING | 元素之间的分隔符 |
| nullReplacement | STRING | 可选；给出时代替NULL元素参与连接 |

返回：STRING；NULL元素默认跳过，指定nullReplacement时以其代替。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY_JOIN(ARRAY['a','b'], '-') FROM bid;
```

输出：STRING；每行均为'a-b'。

| 输入 | 输出 | 说明 |
|---|---|---|
| ARRAY_JOIN(ARRAY['a','b'], '-') | a-b | 以'-'连接各元素 |
| ARRAY_JOIN(ARRAY['a',NULL,'b'], '-') | a-b | NULL元素默认被跳过 |
| ARRAY_JOIN(ARRAY['a',NULL,'b'], '-', 'x') | a-x-b | nullReplacement'x'代替NULL参与连接 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`ARRAY_JOIN`条目（SCALAR） |
| 求值逻辑 | `ArrayJoinFunction`的`eval()`（flink-table-runtime，经`BridgingSqlFunctionCallGen`调用） |

## velox实现

velox已有内建`array_join`（`velox/functions/prestosql/registration/ArrayFunctionsRegistration.cpp`）。
