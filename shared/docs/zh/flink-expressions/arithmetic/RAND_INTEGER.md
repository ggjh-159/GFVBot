# RAND_INTEGER

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回[0, bound)内均匀分布的INTEGER。不带seed时为非确定函数，每行独立抽取；带seed时抽取序列可复现。用于随机分桶与测试数据生成。

## 用法

签名：`RAND_INTEGER(bound)`或`RAND_INTEGER(seed, bound)`

| 参数 | 类型 | 说明 |
|---|---|---|
| bound | INT | 抽取上界（开区间），返回值落在[0, bound) |
| seed | BIGINT | 可选随机种子，指定后抽取序列可复现 |

返回：[0, bound)内的INTEGER；非确定。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, RAND_INTEGER(100) FROM bid;
```

输出：[0, 100)内的INTEGER；每行重新抽取（非确定）。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| RAND_INTEGER(100) | 42 | 一次抽取的示例值，不可复现 |

输出每行重新生成（非确定），此处展示一次抽取的值。

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`RAND_INTEGER`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`RAND_INTEGER`条目（SCALAR） |
| 求值逻辑 | 经`RandCallGen`生成算子内的Random成员（带seed可复现） |

## velox实现

同`rand`注册中的整型带界形态rand(bound)（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
