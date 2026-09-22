# AT

分类：[集合函数](../index.md#集合函数) · 别名：`[]`, ITEM

## 定位与场景

下标访问运算符：`arr[i]`读取数组第i个元素（下标1基），`map[k]`按键查找map中的值。内部注册名为ITEM——报错信息里显示的就是这个名字。

## 用法

签名：`arr[i]`/`map[k]`——中缀运算符形式，非函数调用。

| 参数 | 类型 | 说明 |
|---|---|---|
| arr | ARRAY<T> | 被下标访问的数组 |
| i | INT | 数组下标，1基——首元素下标为1 |
| map | MAP<K, V> | 被按键查找的map |
| k | K | 查找用的键，类型为map的键类型 |

返回：数组元素类型或map的值类型。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, ARRAY[bid.auction, bid.bidder, 99][3] FROM bid;
```

输出：BIGINT；每行均为99——字面量数组的第三个元素。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | bidder | ARRAY[auction, bidder, 99][3] |
|---|---|---|
| 3 | 15 | 99 |
| 19 | 7 | 99 |
| 8 | 8 | 99 |
| 1 | 42 | 99 |
| 14 | 23 | 99 |
| 7 | 2 | 99 |
| 11 | 11 | 99 |
| 20 | 36 | 99 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`AT`条目（SCALAR） |
| 求值逻辑 | 经`ExprCodeGenerator`的ITEM分支内联生成（数组下标/map查找） |

## velox实现

velox已有内建`subscript/element_at`（`velox/functions/prestosql/registration/GeneralFunctionsRegistration.cpp`）。
