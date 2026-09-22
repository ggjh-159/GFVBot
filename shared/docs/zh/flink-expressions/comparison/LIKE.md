# LIKE

分类：[比较函数](../index.md#比较函数) · 别名：—

## 定位与场景

SQL通配匹配：`%`匹配任意字符序列，`_`恰好一个字符；ESCAPE指定转义字符。区分大小写。按形态过滤名称与id。

## 用法

签名：`s LIKE pattern [ESCAPE c]`——s为被检字符串，pattern为含通配符的模式串，ESCAPE c为可选的转义字符子句。

返回：BOOLEAN；s与pattern匹配为TRUE，否则为FALSE。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, bid.extra LIKE '%A%' FROM bid;
```

输出：BOOLEAN；`extra`包含'A'时为true（随行数据变化）。

示例（16行源的前8行，示意数据，末行补空值边界；前列为输入列，末两列为该行结果与说明）：

| extra | extra LIKE '%A%' | 说明 |
|---|---|---|
| A3F19C27B4E0 | TRUE | 含'A'，`%`通配两侧任意序列 |
| 8B2D4F90A1C3 | TRUE | 含'A' |
| C7E5A0D39F16 | TRUE | 含'A' |
| ZK9M2Q7XVBT5 | FALSE | 不含'A' |
| D4C8B1E6A2F7 | TRUE | 含'A' |
| 5F0A9D3C7E8B | TRUE | 含'A' |
| ZZYYXXWWVVUU | FALSE | 不含'A' |
| E2B7F5A9C3D0 | TRUE | 含'A' |
| NULL | UNKNOWN | 任一侧为NULL得UNKNOWN |

## 源码位置

GFV实现该表达式的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`LIKE`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`LIKE`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`把LIKE转交`LikeCallGen`（编译好的模式作为算子可复用成员缓存） |

## velox实现

velox已有内建`like`（`velox/functions/prestosql/registration/StringFunctionsRegistration.cpp`）。
