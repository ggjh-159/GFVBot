# COSH

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回x的双曲余弦，输出恒不小于1；为指数族的偶函数成分。

## 用法

签名：`COSH(x)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | DOUBLE | 任意实数 |

返回：DOUBLE；不小于1。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, COSH(1) FROM bid;
```

输出：DOUBLE；`COSH(1)`每行均为1.543080634815244。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| COSH(1) | 1.543080634815244 | 即(e+1/e)/2在x=1处的值 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`COSH`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`COSH`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`的静态方法（经`MethodCallGen`调用） |

## velox实现

velox已有内建`cosh`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
