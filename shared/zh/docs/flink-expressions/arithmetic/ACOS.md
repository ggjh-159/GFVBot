# ACOS

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回x的反余弦主值，以弧度表示，值域为[0, π]。输入须落在[-1, 1]内，超出该域（|x| > 1）返回NULL；用于由相似度或比率输入换算角度。

## 用法

签名：`ACOS(x)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | DOUBLE | 余弦值，有效域为[-1, 1] |

返回：DOUBLE，[0, π]内的弧度；|x| > 1时为NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ACOS(0.5) FROM bid;
```

输出：DOUBLE；`ACOS(0.5)`每行均为1.0471975511965979。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| ACOS(0.5) | 1.0471975511965979 | 余弦值0.5对应弧度π/3 |
| ACOS(2) | NULL | 输入超出[-1, 1]，返回NULL |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`ACOS`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`ACOS`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`的静态方法（经`MethodCallGen`调用） |

## velox实现

velox已有内建`acos`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
