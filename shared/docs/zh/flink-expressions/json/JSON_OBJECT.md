# JSON_OBJECT

分类：[JSON函数](../index.md#JSON函数) · 别名：—

## 定位与场景

由KEY VALUE对构造JSON对象并序列化为文本；NULL ON NULL把NULL值保留为JSON null，ABSENT ON NULL把该键值对整体省略。用于把列数据组装成事件载荷。

## 用法

签名：`JSON_OBJECT([k VALUE v, ...] [NULL ON NULL | ABSENT ON NULL])`——键为STRING字面量。

| 参数 | 类型 | 说明 |
|---|---|---|
| k | STRING字面量 | JSON对象的键 |
| v | 任意类型 | 键对应的值，按JSON编码 |

NULL ON NULL保留NULL值为JSON null，ABSENT ON NULL省略该键值对。

返回：STRING；JSON对象的序列化文本。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_OBJECT('k' VALUE 42) FROM bid;
```

输出：STRING；每行均为'{"k":42}'。

| 输入 | 输出 | 说明 |
|---|---|---|
| JSON_OBJECT('k' VALUE 42) | {"k":42} | 单键值对 |
| JSON_OBJECT('k' VALUE NULL NULL ON NULL) | {"k":null} | NULL ON NULL：NULL值保留为JSON null |
| JSON_OBJECT('k' VALUE NULL ABSENT ON NULL) | {} | ABSENT ON NULL：该键值对被省略 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`JSON_OBJECT`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`JSON_OBJECT`条目（SCALAR） |
| 求值逻辑 | 专属`JsonObjectCallGen` |

## velox实现

velox仓库暂无对应实现；相近的`json_extract`等族（`velox/functions/prestosql/registration/JsonFunctionsRegistration.cpp`）走自有路径语法，与SQL/JSON标准不同。
