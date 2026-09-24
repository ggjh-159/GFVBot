# Task prompt — stateless expression development

Paste this into your AI agent (Claude Code / opencode) in the target project, fill in the <placeholders>, and send.

Implement the `<function>` stateless expression end to end across velox, velox4j, and gluten-flink.

- Goal: <the expression's semantics: input types, output type, edge cases>
- Verification: <how to check correctness: SQL queries exercising the expression, unit tests at each layer>
- Acceptance: <what counts as done: results match Flink's own implementation, tests pass at all three layers>
- Notes: <anything else the agent should know: related functions to model after, corner cases>

Follow the installed stateless-expression-development workflow; start from the SPEC stage.
