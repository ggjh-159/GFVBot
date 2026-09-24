---
name: flink-velox-build
description: 在GFV工作区经工作区编译脚本编译velox4j（含原生.so）与gluten-flink，并把jars部署进本地Flink安装。
---

# flink-velox-build

## 用途

在目标工作区构建GFV栈的核心产物：

- velox4j，含其原生C++库
- gluten-flink（planner / loader / runtime）

并把产出的jars放到本地Flink安装的加载位置。

## 本技能假定的工作区布局

- 源码仓在`<workspace>/repos/`下（velox、velox4j、gluten、flink），由`gfvbot clone`铺设。
- 除包管理器依赖（`gfvbot env`）外，构建会链接velox的源码级C++库（boost、folly链、protobuf、arrow等），它们在`/usr/local`——在`gfvbot env-init`清单里勾选`source-deps`安装，由velox仓自带的官方setup脚本驱动。新机器`gfvbot clone`之后勾一次即可。
- 工作区环境档案`.gfvbot/env.json`（`gfvbot env`产出、`gfvbot clone`扩充）是路径的唯一来源：仓库位置、flink安装、JAVA_HOME、nexmark jar。不要硬编码路径，也不要在旁边手写配置。
- 编译入口是本技能的`bin/compile.sh`。它从自身位置向上定位`.gfvbot/env.json`，构建velox4j、装进本地Maven仓、基于它构建gluten-flink、把产出的jars拷进flink安装的`lib/`。

## 用法

```bash
bash bin/compile.sh > tmp/<task-name>/logs/cmd-outputs/build-all.log 2>&1
tail -5 tmp/<task-name>/logs/cmd-outputs/build-all.log
```

相对本技能目录运行`bin/compile.sh`（或在工作区任意位置以绝对路径调用）。检查退出码与日志尾部；失败时grep日志找第一个错误，重跑前先读既有日志——只有输入变了才值得重跑。

## 纪律

- 绝不跳过C++构建。`-Dskip.cpp.build`之类的开关或强切C++捷径产出的jar只有Java、内置.so与C++源码失同步——这种漂移日后以错误结果而非构建错误的形式暴露。全量构建太慢就说出来问，不要默默跳过。
- 临时产物一律落项目目录内，绝不写`/tmp`——用户只看项目目录范围内的产物：任务上下文的构建日志落`tmp/<task-name>/logs/cmd-outputs/build-<描述>.log`；无任务上下文落`<workspace>/.gfvbot/tmp/build-<描述>.log`。用tail/grep查看；全量编译输出几万行，拉进上下文就是浪费窗口。
- 构建后，起集群或跑验证前确认新jars确实落进`$FLINK_HOME/lib/`。陈旧jar在运行期与代码bug无法区分。
- 工作树带未提交修复时（例如nexmark侧时间戳或sink补丁），验证前确认每个修复都进了产物——重编的.so漏掉一个待定修复就毁掉整场对比。
- 只改Java源码时增量重建没问题；C++改动必须跑原生构建。
