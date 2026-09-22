# MAP

分类：[值构造函数](../index.md#值构造函数) · 别名：—

## 定位与场景

map构造器：`MAP[k1, v1, k2, v2, ...]`按键值交替书写，键与值各自统一类型。用于构造小型内联查找表。

## 用法

签名：`MAP[k1, v1, k2, v2, ...]`——构造器语法，键值交替，非普通函数调用。

| 参数 | 类型 | 说明 |
|---|---|---|
| k1, k2, ... | 任意类型 | 键，位于交替序列的奇数位，须互相同型 |
| v1, v2, ... | 任意类型 | 值，位于交替序列的偶数位，须互相同型 |

返回：MAP<K, V>；K、V分别为键与值的公共类型。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, MAP['k1', bid.auction, 'k2', bid.bidder] FROM bid;
```

输出：MAP<STRING, BIGINT>；每行为`{k1=auction, k2=bidder}`。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | bidder | MAP['k1', auction, 'k2', bidder] |
|---|---|---|
| 3 | 15 | {k1=3, k2=15} |
| 19 | 7 | {k1=19, k2=7} |
| 8 | 8 | {k1=8, k2=8} |
| 1 | 42 | {k1=1, k2=42} |
| 14 | 23 | {k1=14, k2=23} |
| 7 | 2 | {k1=7, k2=2} |
| 11 | 11 | {k1=11, k2=11} |
| 20 | 36 | {k1=20, k2=36} |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`MAP`条目（SCALAR） |
| 求值逻辑 | 经`ExprCodeGenerator`的MAP_VALUE_CONSTRUCTOR分支内联为`GenericMapData`构造 |

## velox实现

velox已有内建`map`（`velox/functions/prestosql/registration/MapFunctionsRegistration.cpp`）。
