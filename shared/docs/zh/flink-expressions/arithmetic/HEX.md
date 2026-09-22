# HEX

分类：[算术函数](../index.md#算术函数) · 别名：—

## 定位与场景

返回输入的十六进制文本：数值输入渲染为其十六进制数字，字符串输入渲染为其各字节的十六进制（每字节两个十六进制字符）；用于紧凑的字节级视图与连接键。

## 用法

签名：`HEX(x)`

| 参数 | 类型 | 说明 |
|---|---|---|
| x | 数值或STRING | 数值输入按其值渲染，字符串输入按其字节渲染 |

返回：STRING；十六进制文本。

```sql
-- 16行有界bid源：auction BIGINT、bidder BIGINT、price DECIMAL(10,2)、dateTime TIMESTAMP(3)、extra STRING
SELECT auction, bidder, 0.908 * price + 10, HEX(bid.extra) FROM bid;
```

输出：STRING；每行`extra`字节的24个十六进制字符。

示例（16行源的前8行，示意数据；前列为输入列，末列为该行结果）：

| extra | HEX(extra) | 说明 |
|---|---|---|
| A3F19C27B4E0 | 413346313943323742344530 | 12个ASCII字符逐个展开为两个十六进制字符，共24个 |
| 8B2D4F90A1C3 | 384232443446393041314333 | '8'→38、'B'→42，逐字符对应 |
| C7E5A0D39F16 | 433745354130443339463136 | 逐字节十六进制编码 |
| ZK9M2Q7XVBT5 | 5A4B394D3251375856425435 | 'Z'→5A、'K'→4B |
| D4C8B1E6A2F7 | 443443384231453641324637 | 逐字节十六进制编码 |
| 5F0A9D3C7E8B | 354630413944334337453842 | '5'→35、'F'→46 |
| ZZYYXXWWVVUU | 5A5A59595858575756565555 | 重复字符逐次展开 |
| E2B7F5A9C3D0 | 453242374635413943334430 | 逐字节十六进制编码 |
| HEX(255) | FF | 数值输入形态：渲染为其十六进制数字 |

## 源码位置

GFV实现该函数的velox侧逻辑时，可参考的Flink 1.19.2源码位置：

| 环节 | 位置 |
|---|---|
| 解析识别 | `FlinkSqlOperatorTable`的`HEX`条目 |
| 函数定义与类型推导 | `BuiltInFunctionDefinitions`的`HEX`条目（SCALAR） |
| 求值逻辑 | 经`MethodCallGen`直调`BuiltInMethods`的`HEX_STRING`/`HEX_LONG` |

## velox实现

velox已有实现：sparksql套件的`hex`（`velox/functions/sparksql/registration/RegisterMath.cpp`）。
