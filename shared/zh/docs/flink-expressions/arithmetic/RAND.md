# RAND

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回[0, 1)上均匀分布的DOUBLE。不带seed时为非确定函数，每行独立抽取；带seed时抽取序列可复现。用于抽样、负载打散与合成列。

## 用法

签名：`RAND()`或`RAND(seed)`

| 参数 | 类型 | 说明 |
|---|---|---|
| seed | BIGINT | 可选随机种子，指定后抽取序列可复现 |

返回：[0.0, 1.0)内的DOUBLE；非确定。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, RAND() FROM bid;
```

输出：[0.0, 1.0)内的DOUBLE；每行重新抽取（非确定）。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| — | 0.5310239745577783 | 一次抽取的示例值，不可复现 |

输出每行重新生成（非确定），此处展示一次抽取的值。

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`RAND`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`RAND`条目（SCALAR） |
| 求值逻辑 | 经`RandCallGen`生成算子内的Random成员（带seed可复现） |

## velox实现

velox已有内建`rand/random`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
