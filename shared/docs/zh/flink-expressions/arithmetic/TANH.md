# TANH

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回x的双曲正切，输出始终落在(-1, 1)内；用于把特征压缩到有界区间，是常用的预归一化手段。

## 用法

签名：`TANH(x)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | DOUBLE | 任意实数 |

返回：DOUBLE，落在(-1, 1)内。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, TANH(1) FROM bid;
```

输出：DOUBLE；`TANH(1)`每行均为0.7615941559557649。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| TANH(1) | 0.7615941559557649 | 输出严格介于-1与1之间 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`TANH`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`TANH`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`的静态方法（经`MethodCallGen`调用） |

## velox实现

velox已有内建`tanh`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
