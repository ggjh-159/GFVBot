# 三仓单元测试

velox（C++）、velox4j（C+++Java）、gluten-flink（Java）各自的测试放哪、怎么跑、一个新测试该落在哪一层。结构性事实先说：gluten-flink的planner与runtime模块**没有**`src/test`，全部测试住在独立的`ut`模块；velox每个模块带一个`tests/`目录；velox4j在语言边界两侧都有测试，Java测试依赖内嵌的native构建。

| 仓库 | 框架 | 测什么 | 怎么跑 |
|---|---|---|---|
| velox | gtest+ctest | 函数、算子、serde | `make unittest`/`ctest -R`/测试二进制+`--gtest_filter` |
| velox4j | C++ gtest（内嵌构建）+JUnit4 | serde往返、查询执行、队列 | `src/main/cpp/test.sh`/`mvn test` |
| gluten-flink | JUnit5+flink-test-utils | 表达式映射（纯单测）、端到端（MiniCluster） | `mvn test -pl ut -Dtest=X` |

## velox：gtest+ctest

布局惯例：每个模块一个`tests/`子目录、一个`velox_<component>_test`目标。新测试文件加进该模块`tests/CMakeLists.txt`的`add_executable`源列表；链接`${VELOX_TEST_LIBS}`（自带`gtest_main`——不用手写main）；`gtest_discover_tests`把每个`TEST_F`变成独立的ctest条目。全树开关是`VELOX_BUILD_TESTING`（默认开）。

标量函数测试用`FunctionBaseTest`fixture（`velox/functions/lib/tests/FunctionBaseTest.h`）：在`SetUpTestCase`里注册被测函数（`registerFunction<...>`或`registerStatefulVectorFunction`），然后`evaluate("myfunc(C0, C1)", makeRowVector({...}))`加`assertEqualVectors`——表达式字符串本身就是SQL。stateful算子测试住在`velox/experimental/stateful/tests/`：构造`StatefulTask`、喂`StreamRecord`、对输出元素断言。

```bash
cd <velox-build-dir>
make unittest                                  # 全量（跑ctest）
ctest -R RepeatTest                            # 按名过滤
<path>/velox_functions_lib_test --gtest_filter=RepeatTest.repeat   # 可gdb
```

## velox4j：两种语言一份构建

C++侧：构建内嵌velox；`VELOX4J_BUILD_TESTING=ON`打开velox测试树并挂上`src/main/cpp/test/`（目标如`velox4j_query_serde_test`；fixture基于`VectorTestBase`）。一键入口是`src/main/cpp/test.sh`（带测试配置、构建、在`build/test`里`ctest -V`）。serde测试的惯用写法：取一份计划JSON（手写，或从调试日志抓——见[计划序列化](plan-serde.md)），`ISerializable::deserialize`、断言字段、再序列化比对。

Java侧：JUnit4，在`src/test/java/io/github/zhztheplayer/velox4j/`下。承重规则：初始化走`Velox4jTests.ensureInitialized()`（SPARK preset）或`ensureInitializedForFlink()`（FLINK preset），而**同一JVM内preset不能切换**——C++全局注册表只初始化一次。POM的surefire配置因此跑两个execution：默认的排除FLINK preset测试；另一个forked execution只跑它们。新的FLINK preset测试必须落进自己的surefire execution并调`ensureInitializedForFlink()`。native库从jar加载，不需要额外环境。

## gluten-flink：ut模块

一切住在`gluten-flink/ut/`（JUnit5+flink-test-utils），按`rexnode/`、`streaming/api/`、`table/`、`vectorized/`、`velox/`分包。两种形态：

- **纯单测**——样板是`rexnode/RexNodeConverterTest`：用`FlinkTypeFactory`+`FlinkRexBuilder`构造RexNode，跑`RexNodeConverter#toTypedExpr`，断言TypedExpr树。映射改动的秒级反馈（[表达式映射](expression-mapping.md)）。
- **端到端**——基于`GlutenStreamingTestBase`（Flink的StreamingTestBase，内嵌MiniCluster）。关键设施是`runAndCheck`：JNA `dup2`把进程stdout改道进管道，**捕获print连接器的native输出**（它从不经过Java collector——见[运行时执行](runtime-execution.md)），与期望行做diff。nexmark端到端用`NexmarkTest`，带内嵌Kafka source。FLINK preset初始化遵守同样的单preset单JVM规则。

```bash
cd gluten/gluten-flink
mvn test -pl ut -am                              # 该模块及其reactor依赖
mvn test -pl ut -Dtest=RexNodeConverterTest#testMod    # 单个方法
```

上游CI跑测试前会克隆velox4j并打上`gluten-flink/patches/fix-velox4j.patch`——本地与CI结果不一致时先查这个patch。

## 新测试落点

- velox函数→该模块`tests/`，基于`FunctionBaseTest`（`ctest -R MyFuncTest`）
- serde往返（新计划节点）→velox4j C++测试：JSON→反序列化→断言→再序列化→比对
- 算子行为→`velox/experimental/stateful/tests/`，手搭StatefulTask
- 映射回归（新converter）→`ut`的`rexnode/`纯单测
- 端到端（新ExecNode覆盖/链路行为）→`ut`的`GlutenStreamingTestBase`：建表、INSERT/SELECT走print、`runAndCheck`比对行

分层口诀：纯单测能锁住的逻辑（映射、serde）绝不上端到端；端到端只留给必须让Velox真跑起来的行为（算子语义、输出通道）——MiniCluster测试又慢又脆，数量要压住。

## 陷阱

| 症状 | 成因 | 规避 |
|---|---|---|
| `cannot switch to X in the same JVM` | 同一fork里preset已被不同方式初始化 | FLINK preset测试放进自己的surefire execution |
| ut模块解析不到类 | reactor依赖没构建 | 带`-pl ut -am`跑 |
| 新C++测试不执行 | 源文件不在`add_executable`里，或`VELOX_BUILD_TESTING`关着 | 补进源列表；查开关 |
| 本地与CI结果不一致 | CI带着`fix-velox4j.patch` | 先对照patch再debug |
| e2e拖慢构建 | MiniCluster用例太多 | 执行分层口诀；逻辑下推到纯单测 |
