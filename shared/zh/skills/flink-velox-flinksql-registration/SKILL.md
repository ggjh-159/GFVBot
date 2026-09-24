---
name: flink-velox-flinksql-registration
description: 在velox的flinksql命名空间下注册Flink语义的表达式函数——文件放哪、注册怎么写、命名空间如何被加载、什么不能做（复用spark/presto注册）。
---

# flinksql命名空间函数注册

一个Flink语义函数如何作为一等velox函数注册进`velox/functions/flinksql/`。

## 铁律

每个新的GFV表达式函数都实现并注册在**flinksql命名空间**下。禁止复用spark/presto注册（`velox/functions/sparksql/`、`velox/functions/prestosql/`）作为运行时实现——spark/presto的名字只可作语义参考。既有代码里部分已映射表达式仍在复用spark/presto注册，那是过渡状态，不是可效仿的模式。

## 什么放哪

| 部件 | 位置（velox仓内） |
|---|---|
| 函数实现 | `velox/functions/flinksql/<Function或家族>.h`（简单UDF）或`.cpp`（向量函数） |
| 注册入口 | `velox/functions/flinksql/Register.cpp`——命名空间`facebook::velox::functions::flinksql`内的`registerFunctions(prefix)` |
| 头文件 | `velox/functions/flinksql/Register.h` |
| 构建接线 | `velox/functions/flinksql/CMakeLists.txt` |
| 测试 | `velox/functions/flinksql/tests/`——沿用既有表达式测试样式 |

既有的`regexp_extract`（基于re2，`RegexFunctions.h`）是仓内完整flinksql注册的参照；`velox/experimental/stateful/udf/`下的`count_char`/`extract`/`split_index`展示简单UDF形态。

## 注册机制

- 简单UDF：`registerFunction<Fn, ReturnType, ArgTypes...>({prefix + "name"});`——C++结构体实现`call(out, args...)`；NULL处理由框架负责，除非函数刻意用`arg_type<...>`配合`OptionalSetter`/`fill_null`语义自行覆盖。
- 向量函数：`exec::registerStatefulVectorFunction(prefix + "name", signatures(), makeFactory);`——行为依赖运行期类型或常量参数时需要。
- 签名清单：每个受支持的类型组合一条；保持显式——不用悄然扩大覆盖面的万能模板。
- 假定prefix之前先核实命名空间怎么加载：grep velox4j里`registerFunctions`的调用点，看启动时实际用的prefix，新函数沿用同一prefix方案。

## 注册之外的接线

注册velox函数必要但不充分——Flink调用得能到达它：

1. gluten planner：Flink函数名在`gluten-flink/planner/.../rexnode/functions/RexCallConverterFactory.java`里映射到velox函数名。定位映射条目（grep函数名）；新增或扩展一条指向新flinksql限定名的条目。
2. 写全量测试矩阵之前，先在GFV集群上用单条SQL投影（`SELECT <fn>(...) FROM <有界src>`）打通端到端。

## 检查清单

- [ ] 实现文件落在`velox/functions/flinksql/`下，命名空间正确
- [ ] 注册条目进`Register.cpp`，签名显式
- [ ] `CMakeLists.txt`编译新文件
- [ ] flinksql单测覆盖类型矩阵与null/边界行为
- [ ] 对照velox4j调用点核实加载prefix
- [ ] gluten映射条目已增/已改；GFV上冒烟SQL跑通
- [ ] 未复用任何spark/presto注册作为运行时路径
