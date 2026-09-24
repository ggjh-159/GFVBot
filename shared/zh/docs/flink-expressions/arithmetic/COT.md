# COT

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回x的余切，即余弦与正弦之比，操作数为弧度制；正弦为零处无定义（得NULL）。偶见于几何推导。

## 用法

签名：`COT(x)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | DOUBLE | 弧度制的角，正弦为零处无定义 |

返回：DOUBLE。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, COT(1) FROM bid;
```

输出：DOUBLE；`COT(1)`每行均为0.6420926159343306。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| COT(1) | 0.6420926159343306 | 即cos(1)/sin(1) |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`COT`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`COT`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`的静态方法（经`MethodCallGen`调用） |

## velox实现

velox已有实现：sparksql套件的`cot`（`velox/functions/sparksql/registration/RegisterMath.cpp`）。
