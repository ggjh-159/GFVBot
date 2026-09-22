# IS_NOT_FALSE

分类：[逻辑函数](../index.md#逻辑函数) · 别名：—

## 定位与场景

输入为TRUE或UNKNOWN时返回TRUE——即除恰为FALSE以外的所有取值。IS NOT TRUE的镜像，用于把UNKNOWN当作非FALSE处理。

## 用法

签名：`x IS NOT FALSE`（后缀谓词形式）

| 参数 | 类型 | 说明 |
|---|---|---|
| x | BOOLEAN | 可为NULL |

返回：BOOLEAN；x为TRUE或UNKNOWN得TRUE；结果永不为NULL。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, (bid.auction > 10 IS NOT FALSE) FROM bid;
```

输出：BOOLEAN；`auction > 10`为true或unknown时为true。

示例（16行源的前8行，示意数据，末行补三值边界；前列为输入列，末两列为该行结果与说明）：

| auction | auction > 10 IS NOT FALSE | 说明 |
|---|---|---|
| 3 | FALSE | 内层为FALSE |
| 19 | TRUE | 内层为TRUE，属非FALSE |
| 8 | FALSE | 内层为FALSE |
| 1 | FALSE | 内层为FALSE |
| 14 | TRUE | 内层为TRUE，属非FALSE |
| 7 | FALSE | 内层为FALSE |
| 11 | TRUE | 内层为TRUE，属非FALSE |
| 20 | TRUE | 内层为TRUE，属非FALSE |
| NULL | TRUE | 内层为UNKNOWN，属非FALSE |

## 源码位置

GFV实现该表达式的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`IS_NOT_FALSE`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`IS_NOT_FALSE`条目（SCALAR） |
| 求值逻辑 | 经`ScalarOperatorGens`内联生成 |

## velox实现

velox仓库暂无对应实现。
