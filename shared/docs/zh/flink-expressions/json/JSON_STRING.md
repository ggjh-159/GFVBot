# JSON_STRING

分类：[JSON函数](../index.md#JSON函数) · 别名：—

## 定位与场景

把任意SQL值——包括嵌套ROW与集合类型——序列化为JSON文本，row被编码为JSON数组。是JSON构造方向上的通用编码器。

## 用法

签名：`JSON_STRING(v)`

| 参数 | 类型 | 说明 |
|---|---|---|
| v | 任意类型 | 待序列化的SQL值 |

返回：STRING；值的JSON序列化文本。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_STRING(ROW(1, 'a')) FROM bid;
```

输出：STRING；每行均为'[1,"a"]'——row被序列化为JSON数组。

| 输入 | 输出 | 说明 |
|---|---|---|
| JSON_STRING(ROW(1, 'a')) | [1,"a"] | row被序列化为JSON数组 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`JSON_STRING`条目（SCALAR） |
| 求值逻辑 | 专属`JsonStringCallGen`，经planner的JSON序列化器序列化值树 |

## velox实现

velox仓库暂无对应实现；相近的`json_extract`等族（`velox/functions/prestosql/registration/JsonFunctionsRegistration.cpp`）走自有路径语法，与SQL/JSON标准不同。
