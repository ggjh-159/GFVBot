# DIVIDE

分类：[算术函数](../index.md#算术函数) · 别名：`/`

## 定位与场景

数值除法（中缀`/`）：整型操作数相除返回DOUBLE，Flink不做截断的整数除法；DECIMAL与DECIMAL相除返回按精度推导的DECIMAL。任一操作数为NULL时结果为NULL。用于比率与单位度量。

## 用法

签名：`a / b`（中缀除法）

| 参数 | 类型 | 说明 |
|---|---|---|
| 左操作数 | 数值 | 被除数 |
| 右操作数 | 数值 | 除数 |

返回：整型操作数相除得DOUBLE；DECIMAL操作数相除得按精度推导的DECIMAL。任一操作数为NULL时为NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.auction / 7 FROM bid;
```

输出：DOUBLE；每行的`auction / 7`，如3 / 7 = 0.42857142857142855。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | auction / 7 | 说明 |
|---|---|---|
| 3 | 0.42857142857142855 | 商小于1，保留完整小数 |
| 19 | 2.7142857142857144 | 非整除，商为无限循环小数的DOUBLE近似 |
| 8 | 1.1428571428571428 | 非整除 |
| 1 | 0.14285714285714285 | 商小于1 |
| 14 | 2.0 | 整除，结果仍为DOUBLE |
| 7 | 1.0 | 整除，结果仍为DOUBLE |
| 11 | 1.5714285714285714 | 非整除 |
| 20 | 2.857142857142857 | 非整除 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`DIVIDE`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`DIVIDE`条目（SCALAR） |
| 求值逻辑 | 数值除法经`ScalarOperatorGens`内联生成；DECIMAL除法走`DivCallGen`的保精度路径 |

## velox实现

velox已有内建`divide`（`velox/functions/prestosql/registration/MathematicalOperatorsRegistration.cpp`）。
