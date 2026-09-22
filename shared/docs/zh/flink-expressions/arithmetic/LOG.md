# LOG

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

以显式指定的底base取x的对数；base须为正且不等于1，x须为正，任一条件不满足返回NULL。适用于e与10都不是自然底数的领域。

## 用法

签名：`LOG(base, x)`

| 参数 | 类型 | 说明 |
|---|---|---|
| base | DOUBLE | 对数的底，须为正且不等于1 |
| x | DOUBLE | 真数，须为正 |

返回：DOUBLE；非法底数或非正真数时为NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, LOG(2, 8) FROM bid;
```

输出：DOUBLE；`LOG(2, 8)`每行均为3.0。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| LOG(2, 8) | 3.0 | 2的3次幂为8 |
| LOG(1, 8) | NULL | 底数等于1，非法 |
| LOG(2, -8) | NULL | 真数非正，非法 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`LOG`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`LOG`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`的静态方法（经`MethodCallGen`调用） |

## velox实现

velox已有实现：sparksql套件的`log`（`velox/functions/sparksql/registration/RegisterMath.cpp`）。
