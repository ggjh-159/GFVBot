# TYPEOF

分类：[类型转换函数](../index.md#类型转换函数) · 别名：—

## 定位与场景

把参数的运行时类型作为STRING返回（如`BIGINT NOT NULL`）；可选force标志按原样求参数的SQL文本。用于调试动态schema下的类型推导。

## 用法

签名：`TYPEOF(x)`或`TYPEOF(x, force)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | 任意 | 待考察类型的表达式 |
| force | BOOLEAN | 可选；按原样求参数的SQL文本 |

返回：STRING；参数的运行时类型串。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, TYPEOF(bid.auction) FROM bid;
```

输出：STRING；每行均为'BIGINT NOT NULL'。

示例（16行源的前8行，示意数据；前列为输入列，末两列为该行结果与说明）：

| auction | TYPEOF(auction) | 说明 |
|---|---|---|
| 3 | BIGINT NOT NULL | 非空BIGINT列的类型串含NOT NULL标注 |
| 19 | BIGINT NOT NULL | 非空BIGINT列的类型串含NOT NULL标注 |
| 8 | BIGINT NOT NULL | 非空BIGINT列的类型串含NOT NULL标注 |
| 1 | BIGINT NOT NULL | 非空BIGINT列的类型串含NOT NULL标注 |
| 14 | BIGINT NOT NULL | 非空BIGINT列的类型串含NOT NULL标注 |
| 7 | BIGINT NOT NULL | 非空BIGINT列的类型串含NOT NULL标注 |
| 11 | BIGINT NOT NULL | 非空BIGINT列的类型串含NOT NULL标注 |
| 20 | BIGINT NOT NULL | 非空BIGINT列的类型串含NOT NULL标注 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配`BuiltInFunctionDefinitions`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`TYPE_OF`条目（SCALAR） |
| 求值逻辑 | flink-table-runtime的scalar/`TypeOfFunction`的eval()（经`BridgingSqlFunctionCallGen`调用） |

## velox实现

velox已有内建`typeof`（`velox/functions/prestosql/registration/GeneralFunctionsRegistration.cpp`）。
