# ROUND

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

把x四舍五入到d位小数（省略d时为0），常用数值类型按half-up处理；用于金额展示与固定粒度的统计值。

## 用法

签名：`ROUND(x)`或`ROUND(x, d)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | 数值 | 待四舍五入的数值 |
| d | 非负整数字面量 | 保留的小数位数，省略时为0 |

返回：四舍五入到d位小数的数值；类型随输入。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ROUND(bid.price, 1) FROM bid;
```

输出：每行保留1位小数的十进制值，如55.67变55.7。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| price | ROUND(price, 1) | 说明 |
|---|---|---|
| 55.67 | 55.7 | 第2位小数7进位 |
| 12.50 | 12.5 | 第2位小数0舍去 |
| 99.99 | 100.0 | 连续进位使整数部分增一 |
| 3.14 | 3.1 | 第2位小数4舍去 |
| 61.20 | 61.2 | 第2位小数0舍去 |
| 28.05 | 28.1 | half-up：第2位小数5进位 |
| 77.77 | 77.8 | 第2位小数7进位 |
| 45.00 | 45.0 | 已无更低位小数，值不变 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`ROUND`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`ROUND`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`的静态方法（经`MethodCallGen`调用） |

## velox实现

velox已有内建`round`（`velox/functions/prestosql/registration/MathematicalFunctionsRegistration.cpp`）。
