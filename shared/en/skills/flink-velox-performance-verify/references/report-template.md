# GFV performance report: <task/topic>

## Meta

| Item | Value |
|---|---|
| Date | <fill in> |
| GFV build | <fill in: commit/description> |
| Native Flink | 1.19 (<fill in the exact patch version>) |
| Query set | <fill in: q0,qN...> |

## Fixed parameters

| Parameter | Value |
|---|---|
| Data volume | 100M events |
| Generation rate | 50M tps |
| Sink | blackhole |
| Parallelism | p = 1 / 4 / 8 / 16 |
| object-reuse | native runs false/true; GFV runs false only (true crashes) |
| Environment | <fill in: machine, TM x slots> |

## Throughput and ratios (r/s)

The GFV/native columns are GFV-over-native throughput ratios; the r0 baseline is object-reuse=false, the r1 baseline object-reuse=true. A note of `nc:events` marks the row as not comparable (the event count differs across sides); `-` marks a missing capture.

| Query | p | native(r0) | native(r1) | GFV | GFV/native(r0) | GFV/native(r1) | Note |
|---|---|---|---|---|---|---|---|
{{THROUGHPUT_TABLE}}

## Runtime (s)

| Query | p | native(r0) | native(r1) | GFV | Note |
|---|---|---|---|---|---|
{{TIME_TABLE}}

## Unpaired captures

{{UNPAIRED}}

## Conclusion

- Ratio range: <fill in: where GFV/native lands per query and level>
- Environment and noise: <fill in: same-level repeat variance, machine interference>
- Judgement: <fill in: main driver of the gap, advantageous/disadvantageous query shapes, improvement directions>
