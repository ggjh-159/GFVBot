# IS_JSON

分类：[JSON函数](../index.md#JSON函数) · 别名：`IS JSON`

## 定位与场景

中缀谓词，判断文本是否为合法JSON，可加类别限定仅接受某种JSON类型：`v IS JSON [VALUE | ARRAY | OBJECT | SCALAR]`。用于在其他JSON函数之前做准入判断。

## 用法

签名：`v IS JSON [VALUE | ARRAY | OBJECT | SCALAR]`——中缀谓词形式，非函数调用。

| 参数 | 类型 | 说明 |
|---|---|---|
| v | STRING | 待判定的文本 |
| VALUE / ARRAY / OBJECT / SCALAR | — | 可选类别限定，省略时接受任意合法JSON |

返回：BOOLEAN；文本为合法JSON且符合类别限定得TRUE。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, '{"a": 1}' IS JSON FROM bid;
```

输出：BOOLEAN；每行均为true。

| 输入 | 输出 | 说明 |
|---|---|---|
| '{"a": 1}' IS JSON | TRUE | 合法JSON文本 |
| '{"a": 1}' IS JSON OBJECT | TRUE | 类别限定OBJECT：文本是JSON对象 |
| '{"a": 1}' IS JSON ARRAY | FALSE | 类别限定ARRAY：文本不是JSON数组 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | 无算子表专属条目，经`FunctionCatalogOperatorTable`适配 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`IS_JSON`条目（SCALAR） |
| 求值逻辑 | 经`MethodCallGen`调用`FunctionGenerator`注册的`BuiltInMethods`静态方法，无独立运行时类 |

## velox实现

velox仓库暂无对应实现；相近的`json_extract`等族（`velox/functions/prestosql/registration/JsonFunctionsRegistration.cpp`）走自有路径语法，与SQL/JSON标准不同。
