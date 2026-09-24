---
name: flink-velox-unit-test
description: 经本技能的bin/run_velox_test.sh入口跑velox C++单测、经Maven跑velox4j与gluten-flink的Java测试，聚焦目标选择并收集失败现场。
---

# flink-velox-unit-test

## 用途

跨GFV栈三个可测层跑单测，快而聚焦：

- velox C++测试：velox仓debug构建下的gtest目标
- velox4j Java测试：Maven跑JUnit，覆盖经JNI进原生库的数据面
- gluten-flink Java测试：Maven跑JUnit

## 入口

### velox C++测试

```bash
bash bin/run_velox_test.sh <test_target> [gtest_filter]
```

相对本技能目录运行`bin/run_velox_test.sh`（或在工作区任意位置以绝对路径调用）。脚本自行定位工作区环境档案`.gfvbot/env.json`（`gfvbot env`产出、`gfvbot clone`扩充），处理cmake/ctest配置，复用velox4j构建下载的依赖缓存，增量重建——重跑只重编改动的文件。目标命名沿velox树的`velox_<component>_test`。

### velox4j Java测试

```bash
cd "$(jq -r '.repos["velox4j"].path' .gfvbot/env.json)" && mvn test
```

路径取自工作区档案`.gfvbot/env.json`。覆盖JNI路径的用例依赖已构建的原生库——先经flink-velox-build完成含C++的构建。用`-Dtest=ClassName`或`-Dtest=ClassName#method`收窄。

### gluten-flink Java测试

```bash
cd "$(jq -r '.repos["gluten"].path' .gfvbot/env.json)/gluten-flink" && mvn test -pl ut -am
```

`-am`会构建reactor依赖，让父POM与上游模块可解析。聚焦单个改动时用`-Dtest=ClassName`或`-Dtest=ClassName#method`收窄。

## 纪律

- velox C++测试只经本技能的`bin/run_velox_test.sh`跑；手写的cmake、build或ctest调用缺依赖配置，跑出的失败说的是调用方式的问题而不是代码的问题。
- 先跑覆盖改动的最窄测试；全绿或评审方要全套时才放宽到完整目标。
- 多层都改动时按依赖顺序跑：velox C++→velox4j→gluten-flink。
- 失败现场随报告一并收集：`hs_err_pid*.log`、`core.*`、Surefire`*.dumpstream`、测试报告XML。它们是下一步调试的输入。
- 临时产物一律落项目目录内：任务上下文落`tmp/<task-name>/logs/jobs/`（崩溃现场）与`tmp/<task-name>/logs/cmd-outputs/`（测试输出）；无任务上下文落`<workspace>/.gfvbot/tmp/`。绝不写`/tmp`。
- 测试代码遵循项目自身惯例：`testXxx`方法前缀、注释最少——测试靠命名与断言自证行为。
