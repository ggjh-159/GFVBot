# INITCAP

分类：[字符串函数](../index.md#字符串函数) · 别名：—

## 定位与场景

将s中每个以空白分隔的单词转换为首字母大写、其余字母小写的形式，用于把原始名称转换为展示形式。

## 用法

签名：`INITCAP(s)`

| 参数 | 类型 | 说明 |
|---|---|---|
| s | STRING | 待转换的字符串 |

返回：STRING；各单词首字母大写、其余小写。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, INITCAP('hello world') FROM bid;
```

输出：STRING；每行均为'Hello World'。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| INITCAP('hello world') | Hello World | 以空白分隔的两个单词各自首字母大写 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`INITCAP`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`INIT_CAP`条目（SCALAR） |
| 求值逻辑 | `StringCallGen`的`generateInitcap`（直调`SqlFunctionUtils`的`initcap`） |

## velox实现

velox仓库暂无对应实现。
