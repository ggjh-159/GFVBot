# Task prompt — aggregate function development

Paste this into your AI agent (Claude Code / opencode) in the target project, fill in the <placeholders>, and send.

Implement the `<aggregate>` aggregate function: the velox Aggregate with its accumulate / merge / finalize chain, wired into batch execution.

- Goal: <the aggregate's semantics: input types, output type, partial-state layout>
- Verification: <how to check correctness: batch and streaming SQL using the aggregate, unit tests for the accumulate/merge/finalize chain>
- Acceptance: <what counts as done: results match Flink's own aggregator, batch and streaming paths agree>
- Notes: <anything else the agent should know: similar aggregates to model after, state size concerns>

Follow the installed aggregate-function-development workflow; start from the SPEC stage.
