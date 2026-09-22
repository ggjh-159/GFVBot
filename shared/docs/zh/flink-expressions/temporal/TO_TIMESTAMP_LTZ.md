# TO_TIMESTAMP_LTZ

分类：[时间函数](../index.md#时间函数) · 别名：—

## 定位与场景

把原始epoch值按指定精度——0秒、3毫秒、6微秒、9纳秒——转换为TIMESTAMP WITH LOCAL TIME ZONE，呈现随会话时区。适用于转换数值epoch列。

## 用法

签名：`TO_TIMESTAMP_LTZ(numeric, precision)`

| 参数 | 类型 | 说明 |
|---|---|---|
| numeric | BIGINT | 原始epoch值 |
| precision | INT | epoch值的精度：0秒、3毫秒、6微秒、9纳秒 |

返回：TIMESTAMP_LTZ；由epoch值构造、按会话时区呈现的时间戳。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, TO_TIMESTAMP_LTZ(1760000000, 3) FROM bid;
```

输出：TIMESTAMP_LTZ；即2025-10-09T12:26:40Z（epoch毫秒），按会话时区呈现。

示例（输入→输出）：

| 输入 | 输出 | 说明 |
|---|---|---|
| TO_TIMESTAMP_LTZ(1760000000, 3) | 2025-10-09 12:26:40.000 | precision=3按epoch毫秒解释；UTC会话时区呈现 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`TO_TIMESTAMP_LTZ`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`TO_TIMESTAMP_LTZ`条目（SCALAR） |
| 求值逻辑 | `BuiltInMethods`静态方法（经`MethodCallGen`直调） |

## velox实现

velox仓库暂无对应实现。
