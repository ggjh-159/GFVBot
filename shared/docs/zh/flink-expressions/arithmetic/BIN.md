# BIN

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

将整数n转换为二进制（base-2）表示的字符串，不含前导零与前缀；用于检查标志位与id的位级形态。输入须为整数类型。

## 用法

签名：`BIN(n)`

| 参数 | 类型 | 说明 |
|---|---|---|
| n | 整数类型 | 待转换为二进制文本的整数 |

返回：STRING；二进制数字文本。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, BIN(bid.auction) FROM bid;
```

输出：STRING；`auction`的二进制数字（随行数据变化）。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| auction | BIN(auction) | 说明 |
|---|---|---|
| 3 | 11 | 十进制3的二进制表示 |
| 19 | 10011 | 16+2+1 |
| 8 | 1000 | 2的3次幂，1后跟3个0 |
| 1 | 1 | 不补前导零 |
| 14 | 1110 | 8+4+2 |
| 7 | 111 | 三个低位均为1 |
| 11 | 1011 | 8+2+1 |
| 20 | 10100 | 16+4 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`BIN`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`BIN`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateBin`（内联`Long`的`toBinaryString`） |

## velox实现

velox已有实现：sparksql套件的`bin`（`velox/functions/sparksql/registration/RegisterMath.cpp`）。
