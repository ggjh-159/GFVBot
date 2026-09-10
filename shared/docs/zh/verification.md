# 验证工作流

GFV的任何改动——表达式、算子、聚合或性能调整——都走同一个闭环验证：重编jar、重启集群、提交nexmark查询、读结果。本页覆盖闭环全程；编译步骤本身由flink-velox-build skill负责。

前置：按README走查初始化过的工作区（repos已克隆、flink与nexmark经env-init安装、`.gfvbot/env.json`存在）。下文路径来自环境归档：flink安装是`stack.flink.path`，nexmark home（含`bin/run_query.sh`与`queries/`目录）是`stack.nexmark.home`。

## 闭环

- 编译：运行flink-velox-build skill的`bin/compile.sh`。它构建velox4j（含原生.so）与gluten-flink，把四个GFV jar加运行时依赖拷进flink安装的`lib/`，并把集群JDK（`env.java.home`）钉到构建JDK。
- 重启：从flink安装的`bin/`停起集群。TaskManager守护进程在启动时加载`lib/`的全部内容；运行中的守护进程持有旧jar和已加载的原生库，不重启收集到的结果反映的是旧代码。
- 提交：导出FLINK_HOME后运行nexmark的`run_query.sh`。第一个参数是查询类别（`oa`为缺省流式集，`cep`是独立集），第二个是查询号或`all`。
- 观察：提交终端流式打印作业进度，作业到达`FINISHED`后输出基准指标（处理事件数、耗时、吞吐）。作业运行期间flink web UI（8081端口）可看各算子状态与反压。
- 对比：性能工作在同一查询上重跑基线构建并对比指标；固定每次运行的事件数，数字才可比。

```bash
bash <skill-dir>/bin/compile.sh
<flink-home>/bin/stop-cluster.sh && <flink-home>/bin/start-cluster.sh
FLINK_HOME=<flink-home> <nexmark-home>/bin/run_query.sh oa q0
```

## 值得知道的失败模式

- 旧jar：编译后先确认`lib/`里的jar时间戳是新的再起集群；运行期的旧jar与代码bug无法区分。
- 原生库漂移：任何C++改动都需要完整原生构建（绝不跳过）加集群重启；运行中守护进程已加载的JNI库不会随jar替换而换。
- 集群日志报UnsupportedClassVersionError：守护进程的JDK比构建用的旧；编译步骤钉`env.java.home`正是为此，通过安装自带的脚本起集群就会用对JDK。
- blackhole sink：nexmark查询写到blackhole connector，正确性信号是行数与作业指标而不是输出表；按nexmark查询对照表选查询。
