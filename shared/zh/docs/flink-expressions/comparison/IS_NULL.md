# IS_NULL

分类：[比较函数](../index.md#比较函数) · 别名：—

## 定位与场景

判断值是否为NULL，返回普通TRUE或FALSE，绝不返回UNKNOWN，因此是过滤空值唯一可靠的方式。常用于数据质量检查，以及保护会传播NULL的表达式。

## 用法

签名：`x IS NULL`（后缀谓词形式）

| 参数 | 类型 | 说明 |
|---|---|---|
| x | 任意可空类型 | 待判空的值 |

返回：BOOLEAN；x为NULL得TRUE，否则FALSE；结果本身永不为NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction IS NULL) FROM bid;
```

输出：BOOLEAN；本例每行皆为false——`auction`是非空列。

示例（16行源的前8行，示意数据，末行补空值边界；前列为输入列，末两列为该行结果与说明）：

| auction | auction IS NULL | 说明 |
|---|---|---|
| 3 | FALSE | 非NULL值 |
| 19 | FALSE | 非NULL值 |
| 8 | FALSE | 非NULL值 |
| 1 | FALSE | 非NULL值 |
| 14 | FALSE | 非NULL值 |
| 7 | FALSE | 非NULL值 |
| 11 | FALSE | 非NULL值 |
| 20 | FALSE | 非NULL值 |
| NULL | TRUE | 输入为NULL得TRUE，结果永不为NULL |

## 源码位置

GFV实现该表达式的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`IS_NULL`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`IS_NULL`条目（SCALAR） |
| 求值逻辑 | 经`ScalarOperatorGens`内联生成 |

## velox实现

velox已有内建`is_null`（`velox/functions/prestosql/registration/GeneralFunctionsRegistration.cpp`）；sparksql套件另注册`isnull`。
