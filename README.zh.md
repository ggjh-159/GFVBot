# GFVBot

[English](README.md) | [中文](README.zh.md)

GFV（gluten-flink-velox集成路线）的AI底座。核心组织方式是插件化：一个插件对应一个开发场景，自包含该场景的完整开发流程、Agent定义、skills与参考文档，通过安装器安装到目标项目后即可在该项目的AI Agent环境中运行。

> 当前状态：框架（安装器、适配器、测试）已就绪；插件内容（skills / agents / docs）仍在填充中。

## 仓库结构

| 目录 | 职责 |
|---|---|
| `plugins/` | 场景插件，一场景一目录 |
| `shared/` | 跨插件共享的知识资产（skills / docs / templates） |
| `installer/` | 安装器与AI Agent适配（claude / opencode / codex / dsh） |
| `tests/` | 内容资产的测试与看护 |

## 插件

| 插件 | 场景 |
|---|---|
| `stateless-expression-development` | 无状态表达式开发：函数在velox / velox4j / gluten-flink三层的端到端接入 |
| `stateful-operator-development` | 算子开发：stateful算子的规划、执行、状态与数据结构 |
| `aggregate-function-development` | 聚合函数开发：velox Aggregate实现、accumulate/merge/finalize链路与批处理接入 |
| `performance-optimization` | 性能提升：基准对比、profiling、瓶颈定位与优化闭环 |

## 安装

方式一（工具化，推荐）：

```bash
bash installer/setup.sh
cd /path/to/gfv
gfvbot install stateful-operator-development                # 交互式选择AI Agent
gfvbot install stateful-operator-development --tool claude  # 或直接指定AI Agent
```

其余命令与参数运行`gfvbot help`查看。

方式二（克隆仓库后直接调用插件入口）：

```bash
cd /path/to/gfv
bash /path/to/gfvbot/plugins/stateful-operator-development/install.sh claude   # 安装到当前目录
```

目前可选两种AI Agent：`claude`（Claude Code）与`opencode`；`codex`、`dsh`（DeepSeek Harness）的适配器已就绪，待验证环境可用后开放。

## 从零初始化

把一台裸机带到可构建的GFV工作区（支持openEuler、CentOS 7/9与Ubuntu/Debian）：

```bash
bash installer/setup.sh      # 1. 安装gfvbot CLI
cd /path/to/gfv              #    目标项目根目录；以下命令都在这里执行
gfvbot install <plugin>      # 2. 安装场景插件（交互式选择AI Agent）
gfvbot clone                 # 3. 克隆velox/velox4j/gluten/flink到repos/（git缺失时自动补装）
gfvbot env                   # 4. 扫描依赖，归档到.gfvbot/env.json
gfvbot env-init              # 5. 勾选清单安装：构建依赖、flink/nexmark、source-deps
```

每一步都支持续跑：探测到的依赖跳过、已有的仓库与配置不动，中断后重跑同一命令即可继续。

工作区就绪后用flink-velox-build skill构建并启动集群：

```bash
bash <installed-skill>/bin/compile.sh     # velox4j+gluten-flink的jar落进/opt/flink/lib/
/opt/flink/bin/start-cluster.sh
```

## 使用

`gfvbot prompt`打印插件的任务模板：

```bash
gfvbot prompt stateful-operator-development
```

填好占位符，在目标项目根目录启动AI Agent粘贴发送。以TopN任务为例：

```bash
cd /path/to/gfv
claude          # 或opencode
```
```text
> 为gluten-flink开发`TopN`stateful算子。
> - 目标：对流输出按price排序的Top-N
> - 验证：在集群上运行nexmark query `q19`，与原生Flink对比输出
> - 验收：q19输出与原生基线一致，q0-q18不回归
> - 补充：无
> 按已安装的stateful-operator-development工作流推进，从SPEC阶段开始。
```

也可以让AI Agent代填：`--task`加`--tool`在目标项目目录下执行，Agent读插件文档与项目源文件生成完整的任务prompt；`--file`把结果写入文件：

```bash
gfvbot prompt stateful-operator-development --task "开发TopN算子，用nexmark q19验证" --tool claude --file topn-prompt.md
```

`gfvbot list`查看已安装与可安装的插件。

## 环境检查

`gfvbot env`扫描以下内容并归档到目标项目的`.gfvbot/env.json`：

- 构建依赖：git、cmake、gcc/g++、OpenJDK 8/17、Maven、JAVA_HOME
- 构建工具组与Velox系统级C++库组（按组探测、按组安装）
- 本机可用的AI Agent CLI
- flink/nexmark安装情况
- 机器信息：OS、内核、架构、CPU、内存、磁盘

`repos`节记录四个源码仓的路径、克隆源地址、上游地址与主线分支：

- 首次扫描只留占位并提醒
- `gfvbot clone`克隆后自动回填
- 也可直接手工编辑

```bash
gfvbot env
```

发现缺失时，`env`会转交当前OS的安装脚本补齐。想直接调起该安装脚本（交互勾选、安装、装完重扫更新归档）：

```bash
gfvbot env-init
```

env-init的勾选清单同时覆盖运行栈：flink与nexmark两项可选，不勾即跳过。

## 源码仓库

`gfvbot clone`按GFV工作区布局把源码仓库克隆到`<目标>/repos/`，保证不同机器上的仓库布局一致。缺省从基线上游仓克隆基线分支：

| 仓库 | 上游 | 分支 |
|---|---|---|
| velox | bigo-sg | `gluten-20260829` |
| velox4j | bigo-sg | `gluten-20260829` |
| gluten | apache | `main` |
| flink | apache | `release-1.19` |

```bash
gfvbot clone                     # 全部四个仓
gfvbot clone velox velox4j       # 只克隆子集
gfvbot clone --fork <用户名>     # velox/velox4j/gluten改从个人fork仓克隆同分支；flink始终走官方仓
gfvbot clone --shallow           # 浅克隆（--depth 1）
```

完整参数见`gfvbot help`。已存在的仓库跳过不动，重跑同一命令即续补；克隆完成后版本管理直接用git。

## 源码级C++库

包管理器依赖之外，GFV构建还从`/usr/local`链接Velox的源码级C++库（boost、folly链、protobuf、arrow等）。它们通过env-init的勾选清单安装：`gfvbot clone`之后运行`gfvbot env-init`勾选`source-deps`即可——该项仅在velox仓已存在时出现，clone收尾也会打印提醒。

已在`/usr/local`的库自动跳过，重跑只补缺。

## 卸载

```bash
gfvbot uninstall stateful-operator-development            # 装载多个Agent时支持交互勾选卸载
gfvbot uninstall stateful-operator-development --tool claude
```

## 测试

```bash
bash tests/run-tests.sh --fast         # L1静态校验：清单一致性、命名、依赖规则、dry-run
bash tests/run-tests.sh --e2e          # 安装器全生命周期冒烟（一次性沙箱内）
bash tests/run-tests.sh --incremental  # 仅当plugins/或shared/有变更时全量检查
```
