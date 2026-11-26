---
name: flink-velox-format
description: 对velox/velox4j/gluten的改动文件跑各仓canonical格式入口的机器检查（check/fix两模式），check不过即非零退出——所有插件提交前与代码评审第0步共用的唯一格式裁决入口。
---

# Flink-velox代码格式检查

格式问题是机器结论，不占人工评审注意力，也不该进commit。本技能是全部插件共用的唯一入口：提交前check不过不得commit，代码评审第0步取同一结论。

## 按仓分派

| 仓 | check | fix | 覆盖 |
|---|---|---|---|
| velox | C/C++改动文件逐个`clang-format --dry-run --Werror`（按仓根`.clang-format`） | `git add -A`后`make format-fix CHECK_BASE=<base>`——check.py拒绝未暂存改动，默认base为`gluten-20260829`，`VELOX_CHECK_BASE`可改 | 计划节点、算子/函数实现、测试 |
| velox4j | `mvn -q spotless:check` | `mvn -q spotless:apply` | 整个模块 |
| gluten | C/C++改动文件逐个clang-format；Java在`gluten-flink/`根`mvn -q spotless:check -pl planner,ut` | `clang-format -i`；`spotless:apply -pl planner,ut` | `cpp/`与gluten-flink的planner、ut |

仓类型从目录布局自动识别（`gluten-flink/`→gluten，`velox/`＋`.clang-format`→velox，`pom.xml`且名为velox4j→velox4j），识别不了用`--kind`指定。改动文件=未提交工作（已暂存、未暂存、未跟踪新文件），`--base <git-ref>`把该ref之后的提交一并纳入。

## 流程

1. 提交前：`bash bin/format.sh check <repo-path> [--base <git-ref>]`，输出重定向到`tmp/<task-name>/logs/cmd-outputs/format-<repo>-<时间>.log`。
2. 有违规：`bash bin/format.sh fix <repo-path> [--base ...]`，再重跑check。fix只改格式——修完必须重编译并重跑单测；格式修复不与语义改动混在同一个commit里。
3. 评审第0步：reviewer对每个被改仓跑check，以退出码为裁决；IMPLEMENTATION.md与评审报告引用日志路径作为"格式机器检查通过"的证据。

## 判读规则

- 退出码：0干净、1有违规（check）或工具失败（fix）、2用法或环境错误。
- spotless类检查覆盖整个模块，违规清单里可能有非本次改动的文件——那是仓内存量格式债，注明不修，不让存量问题扩大变更面。
- 命令以各仓实际工具链为准（velox的`check.py`/Makefile目标、spotless插件版本）：首次在某仓使用先确认命令可用，不可用即报环境缺口，不静默跳过，更不用临时拼的命令替代。
- 任何"格式已过"的声明必须有check日志路径，没有日志视为未检查。
