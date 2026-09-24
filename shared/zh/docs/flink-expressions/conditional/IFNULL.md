# IFNULL

分类：[条件函数](../index.md#条件函数) · 别名：—

## 定位与场景

两参数版的COALESCE：`IFNULL(a, b)`在a非NULL时取a，否则取b。单列可空值的简洁兜底写法。

## 用法

签名：`IFNULL(a, b)`

| 参数 | 类型 | 说明 |
|---|---|---|
| a | 可统一类型 | 被检值 |
| b | 可统一类型 | a为NULL时的替代值 |

返回：a、b的公共类型；a非NULL取a，否则取b。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, IFNULL(CAST(NULL AS STRING), bid.extra) FROM bid;
```

输出：STRING；即`extra`本身——第一个参数为NULL，取到第二个。

示例（16行源的前8行，示意数据，末行补空值边界；前列为输入列，末两列为该行结果与说明）：

| extra | IFNULL(NULL, extra) | 说明 |
|---|---|---|
| A3F19C27B4E0 | A3F19C27B4E0 | 首参数NULL，取到extra |
| 8B2D4F90A1C3 | 8B2D4F90A1C3 | 首参数NULL，取到extra |
| C7E5A0D39F16 | C7E5A0D39F16 | 首参数NULL，取到extra |
| ZK9M2Q7XVBT5 | ZK9M2Q7XVBT5 | 首参数NULL，取到extra |
| D4C8B1E6A2F7 | D4C8B1E6A2F7 | 首参数NULL，取到extra |
| 5F0A9D3C7E8B | 5F0A9D3C7E8B | 首参数NULL，取到extra |
| ZZYYXXWWVVUU | ZZYYXXWWVVUU | 首参数NULL，取到extra |
| E2B7F5A9C3D0 | E2B7F5A9C3D0 | 首参数NULL，取到extra |
| NULL | NULL | 两个参数均为NULL得NULL |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配`BuiltInFunctionDefinitions`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`IF_NULL`条目（SCALAR） |
| 求值逻辑 | flink-table-runtime的scalar/`IfNullFunction`的eval()（经`BridgingSqlFunctionCallGen`调用） |

## velox实现

velox特型`coalesce`已覆盖两参形态（`velox/expression/RegisterSpecialForm.cpp`）。
