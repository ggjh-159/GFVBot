# ELEMENT

分类：[集合函数](../index.md#集合函数) · 别名：—

## 定位与场景

返回单元素数组中唯一的元素；数组为空得NULL，元素多于一个则报错。用于解包已知单值的结果（如子查询输出）。

## 用法

签名：`ELEMENT(arr)`

| 参数 | 类型 | 说明 |
|---|---|---|
| arr | ARRAY<T> | 待解包的单元素数组 |

返回：T（元素类型）；空数组得NULL，多元素报错。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ELEMENT(ARRAY[bid.auction]) FROM bid;
```

输出：BIGINT；每行即`auction`的值。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | ELEMENT(ARRAY[auction]) |
|---|---|
| 3 | 3 |
| 19 | 19 |
| 8 | 8 |
| 1 | 1 |
| 14 | 14 |
| 7 | 7 |
| 11 | 11 |
| 20 | 20 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`ELEMENT`条目 |
| 函数定义与类型推导 | 无`BuiltInFunctionDefinitions`条目（类型推导随ELEMENT算子经Calcite完成） | |
| 求值逻辑 | 经`ExprCodeGenerator`的ELEMENT分支内联生成（带基数检查的唯一元素读取） |

## velox实现

velox仓库暂无对应实现。
