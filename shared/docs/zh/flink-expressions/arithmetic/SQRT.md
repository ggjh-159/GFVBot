# SQRT

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回x的平方根；负输入（x < 0）返回NULL。用于欧氏距离计算与由方差还原标准差。

## 用法

签名：`SQRT(x)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | DOUBLE | 被开方数，负值返回NULL |

返回：DOUBLE；x < 0时为NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, SQRT(16) FROM bid;
```

输出：DOUBLE；`SQRT(16)`每行均为4.0。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| SQRT(16) | 4.0 | 4的平方为16 |
| SQRT(-1) | NULL | 负输入返回NULL |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`SQRT`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`SQRT`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`的静态方法（经`MethodCallGen`调用） |

## velox实现

velox已有内建`sqrt`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
