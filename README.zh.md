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

其余命令与参数运行 `gfvbot help` 查看。

方式二（克隆仓库后直接调用插件入口）：

```bash
cd /path/to/gfv
bash /path/to/gfvbot/plugins/stateful-operator-development/install.sh claude   # 安装到当前目录
```

目前可选两种AI Agent：`claude`（Claude Code）与 `opencode`；`codex`、`dsh`（DeepSeek Harness）的适配器已就绪，待验证环境可用后开放。

## 使用

`gfvbot prompt` 打印插件的任务模板；`--task`加`--tool`交给AI Agent生成完整的任务prompt（在目标项目目录下执行，Agent会读插件文档与项目源文件来填充内容），`--file`把结果写入文件：

```bash
gfvbot prompt stateful-operator-development
gfvbot prompt stateful-operator-development --task "开发TopN算子，用nexmark q19验证" --tool claude --file topn-prompt.md
```

Claude Code:

```bash
cd /path/to/gfv
claude
```
```text
> <粘贴填好占位符的任务模板>
```

opencode:

```bash
cd /path/to/gfv
opencode
```
```text
> <粘贴填好占位符的任务模板>
```

`gfvbot list` 查看已安装与可安装的插件。

## 环境检查

`gfvbot env` 扫描构建依赖（git、cmake、gcc/g++、OpenJDK 8/17、Maven、JAVA_HOME、构建工具组与Velox系统级C++库组）、本机可用的AI Agent CLI以及flink/nexmark安装情况，并归档到目标项目的`.gfvbot/env.json`；其中`repos`节记录四个源码仓的路径、克隆源地址、上游地址与主线分支，首次扫描只留占位并提醒，`gfvbot clone`克隆后自动回填，也可直接手工编辑。有缺失时转交对应OS的安装脚本（`installer/env-init/`，支持openEuler、CentOS 7/9与Ubuntu/Debian）补齐。安装脚本的勾选清单也覆盖运行栈：flink按官方发行包装到`/opt/flink-<版本>`并建稳定的`/opt/flink`软链，nexmark从源码克隆、maven构建后把jar部署进flink的`lib/`——这两项可选，不勾即跳过：

```bash
gfvbot env
```

想直接调起当前OS的安装脚本（交互勾选、安装、装完重扫更新归档）：

```bash
gfvbot env-init
```

## 源码仓库

`gfvbot clone`按GFV工作区布局把源码仓库克隆到`<目标>/repos/`，保证不同机器上的仓库布局一致。缺省从GFV基线上游仓克隆基线分支（velox/velox4j为bigo-sg的`gluten-0530`，gluten为apache的`main`，flink为apache的`release-1.19`）；`--fork <用户名>`改从个人fork仓（github.com/<用户名>/<仓>）克隆同分支，flink始终走官方仓：

```bash
gfvbot clone                     # 全部四个：velox、velox4j、gluten、flink
gfvbot clone velox velox4j       # 只克隆子集
gfvbot clone --fork <用户名>     # velox/velox4j/gluten改从个人fork仓的基线分支克隆
gfvbot clone --shallow           # 浅克隆（--depth 1）：下载量小、无完整历史
```

已存在的仓库跳过不动；克隆完成后版本管理直接用git。克隆失败自动清掉残缺目录并重试（默认3次），结尾汇总失败项；重跑同一命令即续补，已完成的仓库自动跳过。克隆或跳过的仓库会把路径、克隆源地址（`--fork`时为个人fork仓）、上游地址与主线分支自动回填到`.gfvbot/env.json`的`repos`节。

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
