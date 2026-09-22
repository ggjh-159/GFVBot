# Nexmark query reference

Nexmark models an auction site with three event types — `person`, `auction`, `bid` — generated as a stream. The SQL definitions live in the `queries/` directory of the nexmark installation (`q0.sql` ... `q23.sql`); each query writes to a blackhole sink, so verification goes through row counts and job metrics rather than output tables.

The queries group by what they verify: pick the group that matches the change, start with its first row, then broaden.

### Pipeline liveness

| Query | Shape | Exercises | Use it to verify |
|---|---|---|---|
| q0 | pass-through projection of `bid` | the minimal pipeline: source -> project -> sink | end-to-end liveness after any build |

### Expressions and functions

| Query | Shape | Exercises | Use it to verify |
|---|---|---|---|
| q1 | `0.908 * price` projection | arithmetic on DECIMAL | expression evaluation |
| q2 | `MOD(auction, 123) = 0` filter | filter + built-in function | predicate evaluation |
| q10 | `DATE_FORMAT` columns | date/time functions | datetime handling |
| q21 | `CASE` over channel plus `REGEXP_EXTRACT` | regex plus `CASE` plus filter | string function composition |
| q22 | `SPLIT_INDEX(url, '/', 3..5)` | string splitting | string function throughput |
| q14 | price scale, hour-based `CASE`, `count_char` UDF | scalar UDF plus `CASE` plus time functions | custom function integration |

### Joins

| Query | Shape | Exercises | Use it to verify |
|---|---|---|---|
| q3 | `auction` joins `person` on seller, category/state conditions | two-stream join with string predicates | regular joins |
| q7 | tumble(10s) max price, joined back to `bid` | tumbling window plus join-back | window join over aggregate results |
| q8 | tumble(10s) windows of `person` and `auction` joined on seller | two-stream window join with aligned windows | window joins |
| q13 | `bid` temporal-joins `side_input` at proctime | lookup join against a dimension table | temporal joins |
| q20 | `bid` joins `auction` where category = 10 | inner join with wide projection | join throughput |
| q23 | `bid` joins `person` joins `auction` | three-stream join cascade | multi-way joins |

### Window and aggregation semantics

| Query | Shape | Exercises | Use it to verify |
|---|---|---|---|
| q17 | per auction and day: count/min/max/avg/sum | the basic aggregate family | aggregate correctness |
| q4 | inner `MAX(price)` per auction, outer `AVG` per category | nested two-level aggregation | group aggregation chains |
| q5 | hop(2s/10s) counts per auction, keep per-window max | hopping-window aggregation plus window self-join | windowed aggregation |
| q11 | session(10s) count per bidder | session windows | session window aggregation |
| q12 | proctime tumble(10s) count | processing-time windows | proc-time window aggregation |
| q15 | per-day group with 15 count/filter aggregates | multi-aggregate with `FILTER` clauses | aggregate breadth including count distinct |
| q16 | q15 plus a channel dimension | grouped aggregation at higher cardinality | aggregation under extra grouping keys |

### Ranking and dedup

| Query | Shape | Exercises | Use it to verify |
|---|---|---|---|
| q19 | rank <= 10 per auction by price desc | Top-N ranking | Top-N operators — the canonical pick |
| q9 | `auction` times `bid`, best bid per auction (rank <= 1) | ranking de-dup over a join | Top-1 dedup and wide projections |
| q18 | rank <= 1 per (bidder, auction) by latest time | ranking de-dup | latest-value dedup |
| q6 | best bid per auction, then 10-row sliding `AVG` per seller | sliding rows window over ranked input | not runnable — marked unsupported in the nexmark source |

Scenario picks in one line each: expression work starts at q1/q2 and adds q10/q21/q22, plus q14 for UDF integration; aggregation work starts at q17 and broadens to q15/q16/q4; stateful-operator work takes q3/q5/q8/q13/q18/q19; performance work uses q0 as the throughput baseline and replays the queries its change touches.
