# GFV仓库模块地图

各仓在`<workspace>/repos/`下，由`gfvbot clone`按GFV基线分支铺设。

## repos/velox——velox C++引擎（分支gluten-20260829）

| 路径 | 职责 |
|---|---|
| `velox/exec/` | 批执行：算子、HashTable、RowContainer、聚合 |
| `velox/experimental/stateful/` | 流式有状态扩展：StatefulOperator、keyed算子、窗口聚合器、`state/`下的状态后端 |
| `velox/experimental/connectors/` | 流式connector（nexmark） |
| `velox/expression/` | 表达式求值：函数、binder、vector读取器 |
| `velox/type/`、`velox/vector/` | 类型系统与vector（Arrow背书） |
| `velox/common/`、`velox/core/` | 内存、配置、原语 |
| `_build/debug/` | 跑单测的debug构建树 |

## repos/velox4j——Java/JNI桥（分支gluten-20260829）

| 路径 | 职责 |
|---|---|
| `src/main/java/` | 包装velox计划、表达式与数据的Java API |
| `src/main/cpp/` | JNI原生侧，含被velox测试构建复用的依赖缓存 |

## repos/gluten——gluten集成（分支main）

| 路径 | 职责 |
|---|---|
| `gluten-flink/planner/` | Flink计划→velox计划翻译 |
| `gluten-flink/runtime/` | 算子执行、状态集成、arrow桥接 |
| `gluten-flink/loader/` | 会话、库加载、jar引导 |
| `gluten-flink/ut/` | JUnit测试模块 |
| `gluten-flink/patches/` | 携带的补丁 |

## repos/flink——Flink源码（分支release-1.19）

算子语义、状态后端、planner行为的参照。读它做对比；出厂运行时是装在`$FLINK_HOME`的官方发行版。
