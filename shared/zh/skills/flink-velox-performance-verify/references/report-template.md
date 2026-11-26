# GFV性能测试报告：<任务/主题>

## 元信息

| 项 | 值 |
|---|---|
| 日期 | <填写> |
| GFV构建 | <填写：commit/描述> |
| 原生Flink | 1.19（<填写具体小版本>） |
| 查询集 | <填写：q0,qN...> |

## 固定参数

| 参数 | 值 |
|---|---|
| 数据量 | 1亿events |
| 生成速率 | 5000w tps |
| sink | blackhole |
| 并行度 | p = 1 / 4 / 8 / 16 |
| object-reuse | native测false/true两组；GFV仅false（true会崩溃） |
| 环境 | <填写：机器、TM×slots> |

## 吞吐与比值（r/s）

GFV/native两列是GFV相对原生的吞吐比值（GFV÷native），r0基线=object-reuse false，r1基线=object-reuse true。备注列`nc:events`表示该行两侧事件数不一致、不可比；`-`表示该侧捕获缺失。

| 查询 | p | native(r0) | native(r1) | GFV | GFV/native(r0) | GFV/native(r1) | 备注 |
|---|---|---|---|---|---|---|---|
{{THROUGHPUT_TABLE}}

## 耗时（s）

| 查询 | p | native(r0) | native(r1) | GFV | 备注 |
|---|---|---|---|---|---|
{{TIME_TABLE}}

## 未配对捕获

{{UNPAIRED}}

## 结论

- 比值区间：<填写：各查询各档位GFV/原生落在哪里>
- 环境与噪声：<填写：同档重复波动、机器干扰>
- 判断：<填写：差距主因、优势/劣势查询形态、改进方向>
