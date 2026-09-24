# GFVBot

[English](README.md) | [中文](README.zh.md)

GFV（gluten-flink-velox集成路线）的AI底座。内容按插件组织：一个插件对应一个开发场景，携带该场景的完整开发流程、Agent定义、skills与参考文档；安装到目标项目后，插件在该项目的AI Agent环境中运行。

> 当前状态：框架（安装器、适配器、测试）已就绪；插件内容（skills / agents / docs）仍在填充中。

## 仓库结构

| 目录 | 职责 |
|---|---|
| `plugins/` | 场景插件，一场景一目录：插件自带开发流程（workflow.md）与Agent定义，并声明所需的共享skills与docs |
| `shared/` | 跨插件共享的知识资产：skills（构建、单测、文档检索、代码评审）、docs（架构、验证、nexmark查询、表达式参考、internals深读）、templates |
| `installer/` | 安装器引擎与AI Agent适配（claude / opencode / codex / dsh）：将插件与共享内容安装到目标项目 |
| `tests/` | 内容资产的测试与看护：L1静态校验（清单一致性、en/zh镜像、依赖规则）与安装器e2e冒烟 |

## 插件

一个插件对应一类开发场景，按本次开发目标选择安装：

### `stateless-expression-development`——无状态表达式开发

面向SQL中的标量函数与表达式：字符串、日期时间、数值等**逐行计算、不依赖其他行、不保存中间状态**的函数（如`SPLIT_INDEX`、`EXTRACT`）。该场景下开发一个函数包含三个环节：在velox实现C++向量化版本、建立Flink函数名到velox函数名的映射、打通三层使SQL中的函数调用下推到velox执行。

### `stateful-operator-development`——有状态算子开发

面向窗口聚合、流join、TopN、去重等**需要跨行维护状态**的算子。该场景下开发算子涉及：planner侧将Flink的ExecNode改写为velox计划节点，velox侧实现算子生命周期——状态存取、水位线与timer、checkpoint对齐，并配置nexmark查询用于行为验证。

### `aggregate-function-development`——聚合函数开发

面向SUM/COUNT/AVG及自定义聚合：将多行收敛为单值的函数。该场景的核心是实现velox的Aggregate接口、完成accumulate（累计）/merge（分片合并）/finalize（收尾输出）链路，并接入批式与窗口聚合执行。

### `performance-optimization`——性能提升

用于功能已正确但性能未达要求的场景。流程为闭环：运行nexmark基准与原生Flink对比以量化差距→profiling定位热点（C++/JVM两侧）→修改→回归验证，迭代直至达标。

## 六步从裸机到AI辅助编码

支持openEuler、CentOS 7/9与Ubuntu/Debian。按顺序执行以下步骤，完成后即得到可与AI Agent协同开发的GFV工作区。每一步均支持续跑：已探测的依赖自动跳过、已有仓库与配置保持不变，中断后重新运行同一命令即可继续。

### 第1步：安装gfvbot CLI

```bash
bash installer/setup.sh
```

安装`gfvbot`命令行工具。`gfvbot help`能打印命令列表即表示成功。

### 第2步：安装场景插件

```bash
cd /path/to/gfv      # 目标项目根目录；后续命令均在此执行
gfvbot install stateful-operator-development
```

将插件安装到当前项目——skills、参考文档与开发流程一并安装。不带`--tool`时交互式选择AI Agent，指定`--tool claude`可跳过交互。目前可选`claude`（Claude Code）与`opencode`；`codex`、`dsh`（DeepSeek Harness）适配器已就绪，待验证环境可用后开放。

内容语言随输出语言（`gfvbot lang`），`--lang en|zh`可覆盖。安装后只落一种语言、项目内没有en/zh目录层，切换语言即重新安装覆盖。

`gfvbot list`显示该插件已安装即表示成功。

### 第3步：克隆GFV源码仓

```bash
gfvbot clone
```

将velox/velox4j/gluten/flink四个源码仓克隆到`repos/`下，保证不同机器的工作区布局一致（缺少git时自动安装）。缺省来源：

| 仓库 | 上游 | 分支 |
|---|---|---|
| velox | bigo-sg | `gluten-20260829` |
| velox4j | bigo-sg | `gluten-20260829` |
| gluten | apache | `main` |
| flink | apache | `release-1.19` |

常用参数：`--fork <用户名>`指定velox/velox4j/gluten从个人fork仓克隆同分支（flink始终使用官方仓）；`--shallow`即`--depth 1`；也可指定仓库名克隆子集（`gfvbot clone velox velox4j`）。已存在的仓库跳过；克隆完成后按常规git流程管理。

### 第4步：扫描环境并补齐依赖

```bash
gfvbot env          # 扫描依赖，归档到.gfvbot/env.json
gfvbot env-init     # 按勾选清单安装缺失项
```

`env`探测构建工具、JDK、Maven、flink/nexmark、本机可用的AI Agent CLI与机器信息。`env-init`调起OS对应的勾选清单安装器：构建依赖、flink/nexmark（两项可选，不勾选即跳过）、source-deps（Velox的源码级C++库，从`/usr/local`链接；velox克隆完成后该项才出现）。

重新运行`gfvbot env`不再报告缺失即表示完成。

### 第5步：构建GFV栈并启动集群

```bash
bash <installed-skill>/bin/compile.sh     # velox4j+gluten-flink的jar进入/opt/flink/lib/
/opt/flink/bin/start-cluster.sh
```

`compile.sh`是插件flink-velox-build skill提供的构建入口。jar进入`/opt/flink/lib/`、集群启动后，环境准备完毕。

### 第6步：发起第一个AI辅助任务

```bash
gfvbot prompt stateful-operator-development
```

打印插件的任务模板。填充占位符后，在项目根目录启动AI Agent（`claude`或`opencode`）粘贴发送。以TopN任务为例：

```text
> 为gluten-flink开发`TopN`stateful算子。
> - 目标：对流输出按price排序的Top-N
> - 验证：在集群上运行nexmark query `q19`，与原生Flink对比输出
> - 验收：q19输出与原生基线一致，q0-q18不回归
> - 补充：无
> 按已安装的stateful-operator-development工作流推进，从SPEC阶段开始。
```

也可由AI Agent生成（在目标项目目录下执行，Agent读取插件文档与项目源文件生成完整prompt）：

```bash
gfvbot prompt stateful-operator-development --task "开发TopN算子，用nexmark q19验证" --tool claude --file topn-prompt.md
```

至此即可开始AI辅助编码：插件的workflow驱动任务从SPEC到验收，skills负责构建与测试，docs说明各层内部机制。

## 其他命令

| 命令 | 作用 |
|---|---|
| `gfvbot uninstall <plugin> [--tool <agent>]` | 卸载插件（装载多个Agent时交互勾选） |
| `gfvbot list` | 查看已安装与可安装的插件 |
| `gfvbot help` | 完整命令与参数说明 |
| `bash plugins/<plugin>/install.sh <agent>` | 不安装CLI时的直接安装入口（从本仓库克隆调用） |
| `bash tests/run-tests.sh --fast` | L1静态校验：清单一致性、命名、依赖规则、dry-run |
| `bash tests/run-tests.sh --e2e` | 安装器全生命周期冒烟（一次性沙箱内） |
| `bash tests/run-tests.sh --incremental` | 仅当`plugins/`或`shared/`有变更时全量检查 |
