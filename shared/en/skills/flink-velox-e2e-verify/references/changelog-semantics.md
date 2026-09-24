# Changelog semantics and the multiset fold

## The four flags

| Flag | Meaning | Fold action |
|---|---|---|
| +I | insert of a new row | add the payload row |
| -U | update-before: the row value being replaced | remove the payload row |
| +U | update-after: the new row value | add the payload row |
| -D | delete of an existing row | remove the payload row |

## Why the fold works without a key

In a retract stream the negative flags carry the exact row being withdrawn, not just a key. So the stream reduces to its final result set with a plain multiset fold over payloads — no primary-key knowledge needed:

```
final = multiset()
for row in stream:
    if flag in (+I, +U): final.add(payload)
    if flag in (-U, -D): final.remove(payload)   # must exist; absence = malformed stream
```

## What the fold covers and what it does not

- Append-only queries (plain projection over bounded source) produce only `+I` — the fold is the row set.
- Keyed aggregates produce `-U`/`+U` pairs per change and `-D` on window close — the fold yields the final table.
- Row order and the number of intermediate changes are NOT compared: two runs may take different change paths (different operator chains) and still be correct.
- Duplicate rows matter: the fold is a multiset, so a table legitimately containing two equal rows and one containing a single copy do not match.

## Output formats seen in the wild

Print rows appear in TaskManager `.out` logs as `+I[a, b, c]`. Watch for:

- With parallelism greater than 1, print rows carry a subtask prefix like `3> +I[a, b, c]` — run-sql.sh strips the prefix uniformly at capture time; the fold and the comparison see only `FLAG[payload]`.
- CSV fields containing `,` or `[]` — parse by bracket stripping only (`FLAG[payload]`), never by splitting on commas before extracting the payload.
- NULL rendering: Flink prints null fields as `null` inside the row; both stacks render the same way, so exact string comparison after the fold is valid.
- DECIMAL and TIMESTAMP formatting differences between stacks are real mismatches, not noise — report them.
