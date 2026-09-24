# Nexmark查询对照表

Nexmark用三个事件类型模拟拍卖网站——`person`、`auction`、`bid`——以流的方式生成。SQL定义在nexmark安装目录的`queries/`下（`q0.sql`...`q23.sql`）；每个查询都写入blackhole sink，验证走行数与作业指标而不是输出表。

查询按验证意图分组：按改动挑组，从组内第一行开始，再逐步拓宽。

### 流水线活性

| 查询 | 形状 | 被测特性 | 适合验证 |
|---|---|---|---|
| q0 | `bid`直通投影 | 最小流水线：source→project→sink | 任何构建后的端到端活性 |

### 表达式与函数

| 查询 | 形状 | 被测特性 | 适合验证 |
|---|---|---|---|
| q1 | `0.908 * price`投影 | DECIMAL算术 | 表达式求值 |
| q2 | `MOD(auction, 123) = 0`过滤 | 过滤+内建函数 | 谓词求值 |
| q10 | `DATE_FORMAT`列 | 日期/时间函数 | datetime处理 |
| q21 | channel上的`CASE`加`REGEXP_EXTRACT` | 正则+`CASE`+过滤 | 字符串函数组合 |
| q22 | `SPLIT_INDEX(url, '/', 3..5)` | 字符串拆分 | 字符串函数吞吐 |
| q14 | 价格换算、按小时`CASE`、`count_char` UDF | 标量UDF+`CASE`+时间函数 | 自定义函数接入 |

### Join

| 查询 | 形状 | 被测特性 | 适合验证 |
|---|---|---|---|
| q3 | `auction`按seller连`person`，category/state条件 | 带字符串谓词的双流join | regular join |
| q7 | tumble(10s)最高价，回联`bid` | tumbling窗口+join回联 | 聚合结果上的窗口join |
| q8 | `person`与`auction`的tumble(10s)窗按seller相连 | 窗口对齐的双流window join | window join |
| q13 | `bid`按proctime temporal join `side_input` | 维表lookup join | temporal join |
| q20 | `bid`连`auction`且category=10 | 内join宽投影 | join吞吐 |
| q23 | `bid`连`person`连`auction` | 三流join级联 | 多路join |

### 窗口与聚合语义

| 查询 | 形状 | 被测特性 | 适合验证 |
|---|---|---|---|
| q17 | 按auction+天：count/min/max/avg/sum | 基础聚合全家桶 | 聚合正确性 |
| q4 | 内层按auction取`MAX(price)`，外层按category取`AVG` | 嵌套两层聚合 | group聚合链 |
| q5 | hop(2s/10s)按auction计数，取每窗最大 | hopping窗口聚合+窗口自join | 窗口聚合 |
| q11 | 按bidder的session(10s)计数 | session窗口 | session窗口聚合 |
| q12 | 处理时间tumble(10s)计数 | 处理时间窗口 | proc-time窗口聚合 |
| q15 | 按天分组，15个count/filter聚合 | 带`FILTER`子句的多聚合 | 聚合广度（含count distinct） |
| q16 | q15加channel维度 | 更高基数的分组聚合 | 额外分组键下的聚合 |

### 排名与去重

| 查询 | 形状 | 被测特性 | 适合验证 |
|---|---|---|---|
| q19 | 按auction价格降序取rank≤10 | Top-N排名 | Top-N算子——首选 |
| q9 | `auction`乘`bid`，每auction最高价（rank≤1） | join上的排名去重 | Top-1去重与宽投影 |
| q18 | 按(bidder, auction)取最新时间的rank≤1 | 排名去重 | 最新值去重 |
| q6 | 每auction最高价bid后按seller取10行滑动`AVG` | 排名输入上的滑动行窗口 | 不可运行——nexmark源码标注不支持 |

场景选查一行一条：表达式工作从q1/q2起步，加q10/q21/q22，UDF接入再上q14；聚合工作从q17起步，拓宽到q15/q16/q4；算子工作取q3/q5/q8/q13/q18/q19；性能工作用q0当吞吐基线，改动涉及哪些查询就重放哪些。
