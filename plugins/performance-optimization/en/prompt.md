# Task prompt — performance optimization

Paste this into your AI agent (Claude Code / opencode) in the target project, fill in the <placeholders>, and send.

Optimize `<target>` and close the loop with measurements.

- Goal: <what to optimize: a query, an operator, or a pipeline; and the symptom, e.g. slow query, high CPU>
- Verification: <benchmark to run before and after, e.g. Nexmark query `<qNN>` timings; profiling method, e.g. flamegraph>
- Acceptance: <what counts as done: e.g. latency or throughput improvement of <N>, no correctness regression in <queries>>
- Notes: <anything else the agent should know: suspected bottleneck, prior profiling results, constraints>

Follow the installed performance-optimization workflow; start from the SPEC stage.
