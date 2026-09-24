# 表达式映射：从RexNode到Velox TypedExpr

一个表达式——WHERE谓词、SELECT计算——怎么从Flink planner内部的`RexNode`树走到Velox的`TypedExpr`树，以及新函数两侧各要做什么。先用一句话讲清语义：Flink名→Velox名的字符串映射在Flink侧完成；函数实现按名字在Velox侧查找；两侧都没有兜底——映射缺失或函数未注册都直接让查询失败。

```text
Flink planner（gluten-flink）       velox4j（Java）              velox（C++）
RexNode树                           TypedExpr树                  ITypedExpr树
 |
 +-- RexLiteral  --\
 +-- RexInputRef ---\  RexNodeConverter#toTypedExpr
 +-- RexFieldAccess--/  （类型走LogicalTypeConverter，
 +-- RexCall        /    字面量走toVariant）
        |
        v
   RexCallConverterFactory
   key＝Flink/Calcite算子名
   必须恰好命中一个converter
        |                            |
        +--- 只含名字+参数 ----------+---- Serde -> JSON -> JNI ----> 反序列化
             （CallTypedExpr不带                                       |
              函数元数据）                                             v
                                                          求值期按名解析：
                                                          simpleFunctions()/vector function
                                                          表，由initForFlink()填充
```

| 阶段 | 入口 | 回答的问题 |
|---|---|---|
| 1 分派 | `RexNodeConverter#toTypedExpr`（gluten-flink planner，`rexnode/`） | 每种RexNode子类变成哪个TypedExpr |
| 2 类型 | `LogicalTypeConverter`（gluten-flink **runtime**，与planner共用） | Flink到velox4j的类型表 |
| 3 函数映射 | `RexCallConverterFactory`+各`RexCallConverter`实现（gluten-flink planner，`rexnode/functions/`） | Flink函数调用怎么变成Velox调用、方言差异怎么修 |
| 4 桥 | `TypedExpr`模型+`Serde`（velox4j，`expression/`） | 新函数为什么通常零改velox4j |
| 5 注册 | `initForFlink()`（velox4j的`Init.cc`）+两个register.cpp（velox） | 函数实现放哪、在哪注册 |

## 阶段1：按RexNode子类分派

| RexNode | TypedExpr | 说明 |
|---|---|---|
| `RexLiteral` | `ConstantTypedExpr` | 值经`toVariant`包装（见下） |
| `RexInputRef` | `FieldAccessTypedExpr` | **按列名**引用而不是序号——转换上下文带着上游输出列名表 |
| `RexFieldAccess` | 嵌套`FieldAccessTypedExpr` | 内层引用递归翻译 |
| `RexCall` | 走`RexCallConverterFactory` | 阶段3 |
| 其余 | 抛异常 | 没有静默降级 |

值得记住的`toVariant`细节：精度≤18的DECIMAL（及INTERVAL SECOND）字面量以unscaled值的`BigIntValue`编码；超过则用`HugeIntValue`（int128）——与velox的Decimal双表示对齐。

## 阶段2：类型表

`LogicalTypeConverter`按Flink`LogicalType`的**精确类**匹配。代表行：

| Flink类型 | velox4j类型 |
|---|---|
| BooleanType/IntType/BigIntType/DoubleType | Boolean/Integer/BigInt/Double |
| VarCharType/CharType | VarChar（CHAR归一成VARCHAR） |
| TimestampType/LocalZonedTimestampType | Timestamp（LTZ靠session timezone配置区分） |
| DecimalType(p,s) | Decimal(p,s) |
| DayTimeIntervalType | BigInt |
| RowType/ArrayType/MapType | Row/Array/Map（递归） |

未匹配直接抛`Unsupported logical type`——新数据类型必须来这里加entry。

## 阶段3：converter表

`RexCallConverterFactory`持有一张不可变Map：Flink算子名→候选converter列表。选取时逐个build候选并调`isSuitable`；**必须恰好命中一个**（多个→异常，零个→带各候选失败原因的异常）。名字在这一步转换：`+`→`add`（数值/decimal各一个converter）、`MOD`→`remainder`、`CASE`→`if`、`IS NOT NULL`→`isnotnull`。

两种converter形态：

- `DefaultRexCallConverter(veloxName)`——子表达式递归翻译后组装`CallTypedExpr(returnType, params, veloxName)`。签名同构的函数用它就够；新函数常常只是一行map entry。
- 定制converter（如`SplitIndexRexCallConverter`）——组装前修方言差异：split_index的Flink索引是0起INT而velox要1起BIGINT；分隔符可能以ASCII码字面量出现、需转字符串。

## 阶段4：velox4j为什么通常零改动

`CallTypedExpr`只有`functionName+params`，不带任何函数元数据，因此对任意函数名通用；名字多态serde（[计划序列化](plan-serde.md)）已覆盖它。只有引入全新表达式形态（新的special form）才需要新的`TypedExpr`子类加两侧注册。

## 阶段5：velox侧的实现与注册

求值期按名字查函数表，表在原生库加载时填充：`initForFlink()`＝`initForSpark()`（sparksql全量）+`functions::flinksql::registerFunctions()`（叠加方言修正——如无匹配返回NULL的`regexp_extract`，spark返回空串）。

BIGO自定义UDF的扩展点是`velox/experimental/stateful/udf/Register.cpp`：`count_char`、`extract`、`split_index`注册在那里。simple function写法：

- `template <typename T> struct MyFunc { VELOX_DEFINE_FUNCTION_TYPES(T); ... }`
- `bool call(Result& out, const arg_type<In1>& a, ...)`——第一个参数是输出；`arg_type<>`自动解引用输入；返回false表示该行为NULL
- `registerFunction<MyFunc, Return, In1, In2>({"myfunc"})`——同一结构体可注册多组签名

整列逻辑的vector function走`exec::registerStatefulVectorFunction`。

## 新增场景：新增一个表达式

Flink侧（必须，二选一）：

1. 语义同构→一行map entry：`Map.entry("MYFUNC", Arrays.asList(() -> new DefaultRexCallConverter("myfunc")))`。
2. 有方言差异→继承`BaseRexCallConverter`写定制converter（样板：`SplitIndexRexCallConverter`），`isSuitable`如实划分。
3. 函数必须已存在于Flink catalog（内建或`CREATE FUNCTION`）——gluten映射已有的RexCall，不创造函数。新数据类型加`LogicalTypeConverter`entry；新字面量形态加`toVariant`case。

velox4j侧：通常零改动（阶段4）。

velox侧（必须）：实现（优先simple function）、注册到`initForFlink()`可达路径（BIGO UDF：`experimental/stateful/udf/Register.cpp`；方言修正：`functions/flinksql/`）、加测试（见[单元测试](unit-testing.md)；converter侧加`RexNodeConverterTest`用例）。

## 陷阱

| 症状 | 成因 | 规避 |
|---|---|---|
| 规划期报`Function not supported: X` | Flink名没有map entry | 补entry（或定制converter） |
| `Multiple/No suitable converter found` | 候选的`isSuitable`范围重叠或留洞 | 重划边界；选取要求恰好一个 |
| 执行期（C++）报`Function X not registered` | 注册不在`initForFlink()`可达路径 | 把注册调用接进链 |
| decimal字面量值错 | 精度>18必须走HugeInt路径 | 查`toVariant`的decimal分支 |
| velox表达式里报列不存在 | 以为是按序号取列 | 字段访问按名字；上下文必须带上游列名 |
