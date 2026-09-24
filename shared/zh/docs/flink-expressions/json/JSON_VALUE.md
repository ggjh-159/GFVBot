# JSON_VALUE

分类：[JSON函数](../index.md#JSON函数) · 别名：—

## 定位与场景

抽取SQL/JSON路径定位到的标量并按字符串（或RETURNING指定类型）返回；ON EMPTY/ON ERROR子句决定路径缺失或类型不匹配时的行为。用于从JSON载荷中取具体字段值。

## 用法

签名：`JSON_VALUE(json, path [RETURNING t] [on empty/error])`

| 参数 | 类型 | 说明 |
|---|---|---|
| json | STRING | JSON文档文本 |
| path | STRING | SQL/JSON路径，指向标量 |

RETURNING子句指定返回类型；ON EMPTY/ON ERROR子句决定路径缺失或类型不匹配时的行为。

返回：STRING（或RETURNING指定类型）；标量按目标类型渲染。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_VALUE('{"a": 1}', '$.a') FROM bid;
```

输出：STRING；每行均为'1'——数值标量按文本渲染。

| 输入 | 输出 | 说明 |
|---|---|---|
| JSON_VALUE('{"a": 1}', '$.a') | 1 | 数值标量按文本渲染 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`JSON_VALUE`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`JSON_VALUE`条目（SCALAR） |
| 求值逻辑 | 专属`JsonValueCallGen`（planner的codegen/calls），处理ON EMPTY/ON ERROR |

## velox实现

velox仓库暂无对应实现；相近的`json_extract`等族（`velox/functions/prestosql/registration/JsonFunctionsRegistration.cpp`）走自有路径语法，与SQL/JSON标准不同。
