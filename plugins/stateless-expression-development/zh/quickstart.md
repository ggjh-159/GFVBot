# 无状态表达式开发快速上手

## 前置条件

```bash
gfvbot install stateless-expression-development   # 装插件（含skills/docs/模板）
gfvbot clone                                      # 四仓克隆到repos/
gfvbot env && gfvbot env-init                     # 环境扫描与补齐
bash <flink-velox-build技能>/bin/compile.sh        # 构建并部署jars
/opt/flink/bin/start-cluster.sh                   # 起集群
```

## 示例任务：把`UPPER`迁到flinksql命名空间

一个典型任务——velox已有prestosql`upper`，但按铁律须在flinksql命名空间自有注册：

1. **SPEC**：填`spec.md`模板，语义基准取`docs/gfvbot/shared/flink-expressions/string/UPPER.md`
2. **设计**：填`design.md`——文档卡"velox实现"节显示prestosql已有`upper`；语义对照（NULL行为、字符计数）逐维核对；注册设计写`velox/functions/flinksql/`下新文件；映射设计写`RexCallConverterFactory`条目；给出单测/e2e覆盖矩阵
3. **设计审计**：reviewer按`audit-report.md`A节出具结论（通过/不通过），通过后用户门禁1放行
4. **实现**：按方案编码，编译部署（flink-velox-build）、单测（flink-velox-unit-test）、轻量e2e自测；填`implementation.md`；代码审计（B节）通过后用户门禁2放行
5. **测试**：按设计§8矩阵构造全量SQL（filesystem固定输入+print），双端跑原生Flink与GlutenFlink，changelog还原后精确比对（flink-velox-e2e-verify）；填`test-report.md`；结果审计（C节）+回归
6. **复盘**：归档产物，更新`TASK_STATE.md`

## 工作流总览

| 阶段 | 负责人 | 门禁 | 关键产物 |
|---|---|---|---|
| spec | architect | — | SPEC.md |
| design | architect | 设计审计+用户门禁1 | DESIGN.md |
| implement | developer | 代码审计+用户门禁2 | IMPLEMENTATION.md |
| verify | verifier | 结果审计+用户门禁3 | TEST_REPORT.md |
| retro | architect | — | SUMMARY.md |

任务状态实时记录在`tmp/<任务名>/TASK_STATE.md`，会话中断后从它恢复。

## 提示词模板

`gfvbot prompt stateless-expression-development`打印任务模板；`--task`可让AI代填。
