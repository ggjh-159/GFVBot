# IS_FALSE

分类：[逻辑函数](../index.md#逻辑函数) · 别名：—

## 定位与场景

仅当输入恰为FALSE时返回TRUE——UNKNOWN与FALSE不同，此处也返回FALSE。当false与unknown的区别有意义时（如反连接、NOT语义），这是精确的判定方式。

## 用法

签名：`x IS FALSE`（后缀谓词形式）

| 参数 | 类型 | 说明 |
|---|---|---|
| x | BOOLEAN | 可为NULL |

返回：BOOLEAN；仅x恰为FALSE得TRUE，x为UNKNOWN亦得FALSE；结果永不为NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction > 10 IS FALSE) FROM bid;
```

输出：BOOLEAN；仅当`auction > 10`恰为false时为true。

示例（16行源的前8行，示意数据，末行补三值边界；前列为输入列，末两列为该行结果与说明）：

| auction | auction > 10 IS FALSE | 说明 |
|---|---|---|
| 3 | TRUE | 内层为FALSE |
| 19 | FALSE | 内层为TRUE |
| 8 | TRUE | 内层为FALSE |
| 1 | TRUE | 内层为FALSE |
| 14 | FALSE | 内层为TRUE |
| 7 | TRUE | 内层为FALSE |
| 11 | FALSE | 内层为TRUE |
| 20 | FALSE | 内层为TRUE |
| NULL | FALSE | 内层为UNKNOWN，不等于FALSE |

## 源码位置

GFV实现该表达式的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`IS_FALSE`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`IS_FALSE`条目（SCALAR） |
| 求值逻辑 | 经`ScalarOperatorGens`内联生成 |

## velox实现

velox仓库暂无对应实现。
