# JSON_ARRAY

分类：[JSON函数](../index.md#JSON函数) · 别名：—

## 定位与场景

由参数列表构造JSON数组并序列化为文本。NULL ON NULL把NULL元素保留为JSON null，ABSENT ON NULL将其从结果中省略。用于把列值收集成JSON载荷数组。

## 用法

签名：`JSON_ARRAY([v, ...] [NULL ON NULL | ABSENT ON NULL])`

| 参数 | 类型 | 说明 |
|---|---|---|
| v, ... | 任意类型 | 数组元素，按JSON编码 |

NULL ON NULL保留NULL元素为JSON null，ABSENT ON NULL将其省略。

返回：STRING；JSON数组的序列化文本。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, JSON_ARRAY(1, 2, 'a') FROM bid;
```

输出：STRING；每行均为'[1,2,"a"]'。

| 输入 | 输出 | 说明 |
|---|---|---|
| JSON_ARRAY(1, 2, 'a') | [1,2,"a"] | 数值与字符串按JSON编码 |
| JSON_ARRAY(1, NULL NULL ON NULL) | [1,null] | NULL ON NULL：NULL元素保留为JSON null |
| JSON_ARRAY(1, NULL ABSENT ON NULL) | [1] | ABSENT ON NULL：NULL元素被省略 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`JSON_ARRAY`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`JSON_ARRAY`条目（SCALAR） |
| 求值逻辑 | 专属`JsonArrayCallGen` |

## velox实现

velox仓库暂无对应实现；相近的`json_extract`等族（`velox/functions/prestosql/registration/JsonFunctionsRegistration.cpp`）走自有路径语法，与SQL/JSON标准不同。
