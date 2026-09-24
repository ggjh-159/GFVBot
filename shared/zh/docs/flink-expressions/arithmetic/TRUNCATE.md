# TRUNCATE

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

把x在d位小数处截断（省略d时为0），超出d位的数字直接丢弃，不做四舍五入；当ROUND的half-up会产生高估时，截断保持保守结果。

## 用法

签名：`TRUNCATE(x)`或`TRUNCATE(x, d)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | 数值 | 待截断的数值 |
| d | 非负整数字面量 | 保留的小数位数，省略时为0 |

返回：在d位小数处截断的数值；类型随输入。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, TRUNCATE(bid.price, 1) FROM bid;
```

输出：每行在1位小数处截断的十进制值，如55.67变55.6。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| price | TRUNCATE(price, 1) | 说明 |
|---|---|---|
| 55.67 | 55.6 | 直接丢弃第2位小数 |
| 12.50 | 12.5 | 丢弃0，值不变 |
| 99.99 | 99.9 | 直接丢弃第2位小数 |
| 3.14 | 3.1 | 直接丢弃第2位小数4 |
| 61.20 | 61.2 | 丢弃0，值不变 |
| 28.05 | 28.0 | 第2位小数5不进位，直接丢弃 |
| 77.77 | 77.7 | 直接丢弃第2位小数 |
| 45.00 | 45.0 | 已无更低位小数，值不变 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`TRUNCATE`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`TRUNCATE`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`的静态方法（经`MethodCallGen`调用） |

## velox实现

velox已有内建`truncate`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
