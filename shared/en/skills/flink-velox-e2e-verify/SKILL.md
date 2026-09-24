---
name: flink-velox-e2e-verify
description: Run the same SQL on native Flink and GlutenFlink with fixed filesystem input and a print sink, reduce the changelog output (+I/-U/+U/-D) back to the final result set, and compare the two runs exactly.
---

# Flink-velox e2e verification

Dual-run, changelog-aware comparison of one SQL statement between native Flink and GlutenFlink.

## When to use

Verifying that a pushed-down expression, operator, or aggregate behaves identically on both stacks. One SQL runs twice (native cluster, GFV cluster) under identical fixed input; outputs are compared as final result sets, not raw changelog lines.

## Test shape

Every case follows the same shape, so both clusters see byte-identical inputs:

```sql
CREATE TABLE src (
  <typed columns matching the case's data>
) WITH (
  'connector' = 'filesystem',
  'path' = 'file://<abs data dir>',
  'format' = 'csv'
);
CREATE TABLE sink (LIKE src) WITH ('connector' = 'print');
INSERT INTO sink SELECT <the expression or query under test> FROM src;
```

Rules:

- Input is always a bounded CSV file under a case-local directory — never random or generated-at-run-time data, never an unbounded source.
- The sink is always `print`. Bounded input ends the job; a job counts as succeeded only at FINISHED.
- One case = one SQL file. Name cases `NNN_<intent>.sql` and keep them at the **project root** under `e2e/sql/`, with data under `e2e/data/NNN_<intent>/`.

## Evidence tree: `e2e/` at the project root, not under tmp

The SQL expresses verification scope, the data is fixed input, the output is a run capture, the diff is the ruling evidence — all are verification deliverables that accrete across tasks; `tmp/` holds only agent-runtime self-reference artifacts:

```
e2e/
  sql/      NNN_<intent>.sql                verification scope
  data/     NNN_<intent>/*.csv              fixed input
  out/      NNN_<intent>.native.out         latest-round captures (refreshed in place)
            NNN_<intent>.gfv.out
            NNN_<intent>.*.submit.log       submission logs, written automatically next to the out file
  verify/   NNN_<intent>.diff.txt           latest-round comparison report (refreshed in place)
            RESULTS.md                      full-result rollup (refreshed in place each round)
```

- When a same-named case reappears, compare contents first: identical means reuse (this is the regression case bank); different means pick a new intent name.

## Procedure

1. Prepare data and SQL per case (fixed CSV, filesystem DDL, print sink) into `e2e/{sql,data}/`.
2. Submit to native Flink and capture the output: `bin/run-sql.sh native e2e/sql/NNN_<intent>.sql e2e/out/NNN_<intent>.native.out` (env from `.gfvbot/env.json`; print rows land in the TaskManager `.out` logs, the script extracts rows newer than submission time and writes the submission log next to the out file).
3. Restart the cluster on the GFV build, submit the same case, capture: `bin/run-sql.sh gfv e2e/sql/NNN_<intent>.sql e2e/out/NNN_<intent>.gfv.out`.
4. Reduce, compare, and archive the report: `bin/changelog_diff.py e2e/out/NNN_<intent>.native.out e2e/out/NNN_<intent>.gfv.out > e2e/verify/NNN_<intent>.diff.txt`.
5. Write the verification results rollup: after all cases, write `e2e/verify/RESULTS.md` (refreshed in place) — one line per case with FINISHED status on both ends, changelog row counts and flag stats on both ends, the verdict (MATCH/MISMATCH), and the diff path; a final line rolls up the pass count. TEST_REPORT/VERIFY.md only cite that file's path and conclusions, never copying its body.

A case passes only when the comparison reports exact match AND the job reached FINISHED on both stacks.

## Reading changelog output

Print-sink rows carry a change flag: `+I` insert, `-U` update-before, `+U` update-after, `-D` delete. The changelog is an intermediate view; the final result is what matters:

- Retraction payloads identify the row being removed: a `-U`/`-D` row is the exact old value, `+U` the new value. Folding the stream as a multiset (`+I`/`+U` add, `-U`/`-D` remove the given row) recovers the final result set without knowing the key.
- The fold is exact for append-only and keyed upsert outputs; row order is not compared.
- Details and edge cases: `references/changelog-semantics.md`.

## Comparison standard

Exact match, no tolerance: no extra rows, no missing rows, no field-value differences in any row. One mismatching row fails the case; there is no partial pass.
