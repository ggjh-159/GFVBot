# LN

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回x的自然对数（以e为底）；输入非正（x <= 0）时返回NULL。常用于聚合前对偏斜分布做对数缩放。

## 用法

签名：`LN(x)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | DOUBLE | 真数，须为正 |

返回：DOUBLE；x <= 0时为NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, LN(EXP(2)) FROM bid;
```

输出：DOUBLE；`LN(EXP(2))`每行均为2.0。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| LN(EXP(2)) | 2.0 | LN与EXP互为逆运算 |
| LN(0) | NULL | 非正输入返回NULL |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`LN`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`LN`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`的静态方法（经`MethodCallGen`调用） |

## velox实现

velox已有内建`ln`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
