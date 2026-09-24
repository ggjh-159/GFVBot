# LOG10

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回x的常用对数（以10为底）；输入非正（x <= 0）时返回NULL。用于分贝类与数量级度量。

## 用法

签名：`LOG10(x)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | DOUBLE | 真数，须为正 |

返回：DOUBLE；x <= 0时为NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, LOG10(100) FROM bid;
```

输出：DOUBLE；`LOG10(100)`每行均为2.0。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| LOG10(100) | 2.0 | 10的2次幂为100 |
| LOG10(-1) | NULL | 非正输入返回NULL |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`LOG10`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`LOG10`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`的静态方法（经`MethodCallGen`调用） |

## velox实现

velox已有内建`log10`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
