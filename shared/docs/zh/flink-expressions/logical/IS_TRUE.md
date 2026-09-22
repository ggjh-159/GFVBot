# IS_TRUE

分类：[逻辑函数](../index.md#逻辑函数) · 别名：—

## 定位与场景

把三值逻辑归一为二值：仅输入恰为TRUE时返回TRUE，FALSE与UNKNOWN都映射为FALSE。等价于将UNKNOWN按FALSE处理的显式写法。

## 用法

签名：`x IS TRUE`（后缀谓词形式）

| 参数 | 类型 | 说明 |
|---|---|---|
| x | BOOLEAN | 可为NULL |

返回：BOOLEAN；仅x恰为TRUE得TRUE；结果永不为NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction > 10 IS TRUE) FROM bid;
```

输出：BOOLEAN；即`auction > 10`每行的真值（随行数据变化）。

示例（16行源的前8行，示意数据，末行补三值边界；前列为输入列，末两列为该行结果与说明）：

| auction | auction > 10 IS TRUE | 说明 |
|---|---|---|
| 3 | FALSE | 内层为FALSE |
| 19 | TRUE | 内层为TRUE |
| 8 | FALSE | 内层为FALSE |
| 1 | FALSE | 内层为FALSE |
| 14 | TRUE | 内层为TRUE |
| 7 | FALSE | 内层为FALSE |
| 11 | TRUE | 内层为TRUE |
| 20 | TRUE | 内层为TRUE |
| NULL | FALSE | 内层为UNKNOWN，映射为FALSE |

## 源码位置

GFV实现该表达式的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`IS_TRUE`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`IS_TRUE`条目（SCALAR） |
| 求值逻辑 | 经`ScalarOperatorGens`内联生成 |

## velox实现

velox仓库暂无对应实现。
