# JSON_QUERY

分类：[JSON函数](../index.md#JSON函数) · 别名：—

## 定位与场景

抽取SQL/JSON路径定位到的JSON对象或数组，并按JSON文本返回；WRAPPER子句控制结果是否再包一层JSON数组。用于取子文档而非标量。

## 用法

签名：`JSON_QUERY(json, path [RETURNING t] [wrapper] [on empty/error])`

| 参数 | 类型 | 说明 |
|---|---|---|
| json | STRING | JSON文档文本 |
| path | STRING | SQL/JSON路径，指向对象或数组 |

RETURNING子句指定返回类型；WRAPPER子句控制结果是否再包一层JSON数组；ON EMPTY/ON ERROR子句决定路径结果为空与求值出错时的行为。

返回：STRING；JSON子文档的序列化文本。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_QUERY('{"a": {"b": 1}}', '$.a') FROM bid;
```

输出：STRING；每行均为子对象'{"b": 1}'。

| 输入 | 输出 | 说明 |
|---|---|---|
| JSON_QUERY('{"a": {"b": 1}}', '$.a') | {"b": 1} | 抽取路径$.a处的子对象并按JSON文本返回 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`JSON_QUERY`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`JSON_QUERY`条目（SCALAR） |
| 求值逻辑 | 经`MethodCallGen`调用`FunctionGenerator`注册的`BuiltInMethods`静态方法，无独立运行时类 |

## velox实现

velox仓库暂无对应实现；相近的`json_extract`等族（`velox/functions/prestosql/registration/JsonFunctionsRegistration.cpp`）走自有路径语法，与SQL/JSON标准不同。
