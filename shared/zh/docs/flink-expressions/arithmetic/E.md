# E

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回欧拉数e，DOUBLE类型常量；为零参数函数，调用须带空括号写作`E()`。

## 用法

签名：`E()`

无参数。

返回：DOUBLE；恒为2.718281828459045。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, E() FROM bid;
```

输出：DOUBLE；每行均为2.718281828459045。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| — | 2.718281828459045 | 自然对数的底，即Java常量Math.E的DOUBLE值 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`E`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`E`条目（SCALAR） |
| 求值逻辑 | 经`ConstantCallGen`把Math.E常量内联进生成代码 |

## velox实现

velox已有内建`e`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
