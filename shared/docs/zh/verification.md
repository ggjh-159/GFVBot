# 验证工作流

GFV的任何改动——表达式、算子、聚合或性能调整——都走同一个闭环验证：重编jar、重启集群、提交nexmark查询、读结果。本页覆盖闭环全程；编译步骤本身由flink-velox-build skill负责。

前置：按README走查初始化过的工作区（repos已克隆、flink与nexmark经env-init安装、`.gfvbot/env.json`存在）。下文路径来自环境归档：flink安装是`stack.flink.path`，nexmark home（含`bin/run_query.sh`与`queries/`目录）是`stack.nexmark.home`。

## 闭环

```text
        +--------+
        | 编译   |  compile.sh -> 新jar落进flink的lib/
        +--------+
            v
        +--------+
        | 重启   |  停起集群 -> 守护进程加载新jar
        +--------+
            v
        +--------+
        | 提交   |  run_query.sh oa qN -> nexmark作业上集群
        +--------+
            v
        +--------+
        | 观察   |  终端流式打印进度；web UI看算子状态
        +--------+
            v
        +--------+
        | 对比   |  同一查询、固定事件数：基线 vs 改动
        +--------+
            --- 每次改动后重复 ---
```

| 步骤 | 命令 | 要确认什么 |
|---|---|---|
| 编译 | `bash <skill-dir>/bin/compile.sh` | flink`lib/`里的jar时间戳是新的；GFV jar加运行时依赖都落位 |
| 重启 | `<flink-home>/bin/stop-cluster.sh && <flink-home>/bin/start-cluster.sh` | TaskManager在jar落位**之后**重启，而不是之前 |
| 提交 | `FLINK_HOME=<flink-home> <nexmark-home>/bin/run_query.sh oa q0` | 作业到达RUNNING，再到FINISHED |
| 观察 | 提交终端；8081端口的web UI | FINISHED后打印基准指标（处理事件数、耗时、吞吐）；运行期间可见算子状态与反压 |
| 对比 | 在基线构建上重跑同一查询 | 固定每次运行的事件数，数字才可比 |

第一个查询参数是类别（`oa`为缺省流式集，`cep`是独立集），第二个是查询号或`all`。选查询走nexmark查询对照表。

## 失败模式

| 症状 | 成因 | 处置 |
|---|---|---|
| 结果不反映代码改动 | 运行中的守护进程持有旧jar——运行期的旧jar与代码bug无法区分 | 起集群前先查`lib/`里jar的时间戳；重启；重新提交 |
| C++改动没有生效 | 原生构建被跳过，或已加载的JNI库从未被换掉 | 绝不跳过原生构建；每次重编后重启集群 |
| 集群日志报`UnsupportedClassVersionError` | 守护进程的JDK比构建用的旧 | 编译步骤钉了`env.java.home`；通过安装自带的脚本起集群就会用对JDK |
| 没有输出表可对比 | nexmark查询写到blackhole connector | 验证走行数与作业指标；按nexmark查询对照表选查询 |
