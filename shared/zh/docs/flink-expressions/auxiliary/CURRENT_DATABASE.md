# CURRENT_DATABASE

分类：[辅助函数](../index.md#辅助函数) · 别名：—

## 定位与场景

把会话当前数据库名作为STRING返回。用于模板化SQL与环境感知的路由。

## 用法

签名：`CURRENT_DATABASE()`

无参数。

返回：STRING；会话当前数据库名。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, CURRENT_DATABASE() FROM bid;
```

输出：STRING；每行均为'default_database'。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| — | default_database | 未切换数据库时的会话当前库 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`CURRENT_DATABASE`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`CURRENT_DATABASE`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的CURRENT_DATABASE分支经`addReusableQueryLevelCurrentDatabase`内联查询级库名 |

## velox实现

velox仓库暂无对应实现（会话元数据，非求值函数）。
