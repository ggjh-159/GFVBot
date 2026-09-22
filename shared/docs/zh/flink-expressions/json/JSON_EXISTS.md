# JSON_EXISTS

分类：[JSON函数](../index.md#JSON函数) · 别名：—

## 定位与场景

判断SQL/JSON路径在文档中能否定位到至少一个值，定位到返回TRUE。用于对JSON载荷做快速存在性判断。

## 用法

签名：`JSON_EXISTS(json, path)`

| 参数 | 类型 | 说明 |
|---|---|---|
| json | STRING | JSON文档文本 |
| path | STRING | SQL/JSON路径 |

返回：BOOLEAN；路径定位到至少一个值得TRUE。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_EXISTS('{"a": 1}', '$.a') FROM bid;
```

输出：BOOLEAN；每行均为true——路径$.a存在。

| 输入 | 输出 | 说明 |
|---|---|---|
| JSON_EXISTS('{"a": 1}', '$.a') | TRUE | 路径$.a定位到值 |
| JSON_EXISTS('{"a": 1}', '$.b') | FALSE | 路径未定位到任何值 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`JSON_EXISTS`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`JSON_EXISTS`条目（SCALAR） |
| 求值逻辑 | 经`MethodCallGen`调用`FunctionGenerator`注册的`BuiltInMethods`静态方法，无独立运行时类 |

## velox实现

velox仓库暂无对应实现；相近的`json_extract`等族（`velox/functions/prestosql/registration/JsonFunctionsRegistration.cpp`）走自有路径语法，与SQL/JSON标准不同。
