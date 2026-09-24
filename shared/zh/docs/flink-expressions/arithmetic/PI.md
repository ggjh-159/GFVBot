# PI

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回常量π，DOUBLE类型；为零参数函数，调用须带空括号写作`PI()`。

## 用法

签名：`PI()`

无参数。

返回：DOUBLE；恒为3.141592653589793。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, PI() FROM bid;
```

输出：DOUBLE；每行均为3.141592653589793。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| — | 3.141592653589793 | 圆周率，即Java常量Math.PI的DOUBLE值 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`PI_FUNCTION`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`PI`条目（SCALAR） |
| 求值逻辑 | 经`ConstantCallGen`把Math.PI常量内联进生成代码 |

## velox实现

velox已有内建`pi`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
