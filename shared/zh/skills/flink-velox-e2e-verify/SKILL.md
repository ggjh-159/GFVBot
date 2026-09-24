---
name: flink-velox-e2e-verify
description: 以固定文件系统输入与print sink在原生Flink与GlutenFlink上跑同一条SQL，把changelog输出（+I/-U/+U/-D）还原回最终结果集，两端精确对比。
---

# Flink-velox e2e验证

对单条SQL在原生Flink与GlutenFlink之间做双跑、感知changelog的对比。

## 何时使用

验证被下推的表达式、算子或聚合在两栈上行为一致。一条SQL跑两遍（原生集群、GFV集群），输入完全相同固定；以最终结果集对比输出，而非裸changelog行。

## 测试形态

每条用例同一形态，两集群看到的输入字节一致：

```sql
CREATE TABLE src (
  <按用例数据写列与类型>
) WITH (
  'connector' = 'filesystem',
  'path' = 'file://<绝对数据目录>',
  'format' = 'csv'
);
CREATE TABLE sink (LIKE src) WITH ('connector' = 'print');
INSERT INTO sink SELECT <受测表达式或查询> FROM src;
```

规则：

- 输入永远是用例目录下的有界CSV——不用随机或运行期生成的数据，不用无界source。
- sink永远是`print`。有界输入结束作业；作业只有到FINISHED才算成功。
- 一条用例=一个SQL文件。用例命名`NNN_<intent>.sql`，落**项目根**`e2e/sql/`下，数据落`e2e/data/NNN_<intent>/`。

## 证据树：`e2e/`在项目根，不在tmp下

SQL表达验证范围、数据是固定输入、输出是运行捕获、diff是裁决依据——都是验证交付的证据，跨任务沉淀；`tmp/`只是Agent运行时自参考产物：

```
e2e/
  sql/      NNN_<intent>.sql                验证范围
  data/     NNN_<intent>/*.csv              固定输入
  out/      NNN_<intent>.native.out         最新一轮捕获（原地刷新）
            NNN_<intent>.gfv.out
            NNN_<intent>.*.submit.log       提交日志，随out自动生成
  verify/   NNN_<intent>.diff.txt           最新一轮对比报告（原地刷新）
            RESULTS.md                      全量结果汇总（每轮原地刷新）
```

- 同名用例再现时先比对内容：一致即复用（这就是回归用例库），不一致换intent名。

## 流程

1. 按用例备数据与SQL（固定CSV、filesystem DDL、print sink），落`e2e/{sql,data}/`。
2. 提交原生Flink并捕获输出：`bin/run-sql.sh native e2e/sql/NNN_<intent>.sql e2e/out/NNN_<intent>.native.out`（环境取自`.gfvbot/env.json`；print行落在TaskManager`.out`日志，脚本抽取提交时刻之后的新行，提交日志随out自动落盘）。
3. GFV构建上重启集群，提交同一用例并捕获：`bin/run-sql.sh gfv e2e/sql/NNN_<intent>.sql e2e/out/NNN_<intent>.gfv.out`。
4. 还原并对比，报告落档：`bin/changelog_diff.py e2e/out/NNN_<intent>.native.out e2e/out/NNN_<intent>.gfv.out > e2e/verify/NNN_<intent>.diff.txt`。
5. 汇总输出验证结果：全部用例跑完写`e2e/verify/RESULTS.md`（原地刷新）——每用例一行，含两端FINISHED状态、两端changelog行数与标志统计、裁决（MATCH/MISMATCH）、diff路径；末行汇总通过数。TEST_REPORT/VERIFY.md只引用该文件路径与结论，不复制正文。

只有对比精确一致且两栈作业都到FINISHED，用例才算通过。

## 读changelog输出

print行带变更标志：`+I`插入、`-U`更新前、`+U`更新后、`-D`删除。changelog是中间视图，最终结果才是要点：

- 回撤载荷标识被移除的行：`-U`/`-D`行是被撤回的精确旧值，`+U`是新值。按多重集折叠流（`+I`/`+U`加、`-U`/`-D`减去给定行）无需知道key即还原最终结果集。
- 折叠对append-only与keyed upsert输出都精确；不比较行序。
- 细节与边界：`references/changelog-semantics.md`。

## 对比标准

精确一致，零容差：不多行、不少行、任何行的字段值无差异。一行不一致即用例失败，不存在部分通过。
