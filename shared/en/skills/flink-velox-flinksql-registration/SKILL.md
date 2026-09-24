---
name: flink-velox-flinksql-registration
description: Register Flink-semantics expression functions under velox's flinksql namespace — where the files go, how registration is written, how the namespace is loaded, and what must not be done (reusing spark/presto registrations).
---

# flinksql namespace function registration

How a Flink-semantics function is registered as a first-class velox function under `velox/functions/flinksql/`.

## Standing rule

Every new GFV expression function is implemented and registered under the **flinksql namespace**. Reusing a spark/presto registration (`velox/functions/sparksql/`, `velox/functions/prestosql/`) as the runtime implementation is forbidden — spark/presto names may be consulted as semantic references only. The existing codebase still reuses spark/presto registrations for some mapped expressions; that is transitional state, not a pattern to follow.

## What lives where

| Piece | Location (under the velox repo) |
|---|---|
| Function implementation | `velox/functions/flinksql/<Function or family>.h` (simple UDF) or `.cpp` (vector function) |
| Registration entry | `velox/functions/flinksql/Register.cpp` — `registerFunctions(prefix)` in namespace `facebook::velox::functions::flinksql` |
| Header | `velox/functions/flinksql/Register.h` |
| Build wiring | `velox/functions/flinksql/CMakeLists.txt` |
| Tests | `velox/functions/flinksql/tests/` — follow the existing expression test pattern |

The existing `regexp_extract` (re2-based, `RegexFunctions.h`) is the in-tree reference for a full flinksql registration; the stateful-side `count_char`/`extract`/`split_index` under `velox/experimental/stateful/udf/` show the simple-UDF shape.

## Registration mechanics

- Simple UDF: `registerFunction<Fn, ReturnType, ArgTypes...>({prefix + "name"});` — the C++ struct implements `call(out, args...)`; null handling comes from the framework unless the function takes `arg_type<...>` with `OptionalSetter` / `fill_null` semantics the function overrides deliberately.
- Vector function: `exec::registerStatefulVectorFunction(prefix + "name", signatures(), makeFactory);` — needed when behavior depends on runtime types or constant arguments.
- Signature lists: one entry per supported type combination; keep the list explicit — no catch-all templating that silently widens coverage.
- Check how the namespace is loaded before assuming a prefix: grep the `registerFunctions` call sites in velox4j to see the prefix actually used at startup, and use the same prefix scheme for the new function.

## Wiring beyond registration

Registering the velox function is necessary but not sufficient — the Flink call must reach it:

1. gluten planner: the Flink function name maps to a velox function name in `gluten-flink/planner/.../rexnode/functions/RexCallConverterFactory.java`. Locate the map entry (grep the function name); add or extend one entry pointing at the new flinksql-qualified name.
2. Confirm end-to-end with a single SQL projection (`SELECT <fn>(...) FROM <bounded src>`) on the GFV cluster before writing the full test matrix.

## Checklist

- [ ] Implementation file(s) under `velox/functions/flinksql/`, namespace-correct
- [ ] Registration added to `Register.cpp` with explicit signatures
- [ ] `CMakeLists.txt` compiles the new files
- [ ] flinksql unit test covers the type matrix and null/edge behavior
- [ ] Loader prefix verified against velox4j call sites
- [ ] Gluten mapping entry added/updated; smoke SQL runs on GFV
- [ ] No spark/presto registration reused as the runtime path
