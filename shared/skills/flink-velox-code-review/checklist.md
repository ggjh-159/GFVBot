# Flink-Velox Code Review Checklist

> **Usage**: this checklist drives stage 3 (the item-by-item walk) of the `flink-velox-code-review` skill. Walk the sections in order and execute only the sections the change-surface tags trigger. Each item yields exactly one of `- [ ]` (no issue found) or `- [x]` (issue found, with `file:line`).

## Prelude: change-surface tags (stage 1 output)

Derive the change **type tags** from the diff:

| Tag | Condition | Dimensions triggered |
|---|---|---|
| `arrow-res` | added/modified Arrow Vector / Allocator / Session / QueryResult / FieldVector | B resource management |
| `exception` | added/modified try/catch/throw/finally | C exception handling |
| `json-serde` | added/modified JSON serialization classes (VeloxPlan/Expression/Type) | D serialization compatibility |
| `rexcall` | added/modified RexCallConverterFactory / RexNode conversion | A layer boundaries + D serialization compatibility |
| `operator` | added/modified Flink Operator (open/close/processElement) | B resource management + E lifecycle |
| `pointer` | added/modified C++ pointer operations / dynamic_cast / raw ptr | F memory safety |
| `numeric` | added/modified integer arithmetic / array indexing / division | G numeric safety |
| `import` | import-only changes | H import discipline |
| `api-change` | added/modified public method signatures / interfaces | A layer boundaries + D compatibility |
| `other` | none of the above | I general quality only |

## Checklist (stage 3)

### A. Layer boundaries

**Trigger**: tags include `rexcall`, `api-change`, or `import`

- [ ] **A1** planner does not import runtime internal packages (`org.apache.gluten.streaming.*`, `org.apache.gluten.vectorized.*`, `org.apache.gluten.client.*`)
- [ ] **A2** runtime does not import planner packages (`org.apache.gluten.rexnode.*`, `org.apache.gluten.velox.*`)
- [ ] **A3** velox4j public packages do not import internal packages
- [ ] **A4** a new planner mapping has a matching runtime handler (only when the change includes `rexcall`)

> Any violation → CRITICAL, verdict fail

### B. Resource management

**Trigger**: tags include `arrow-res` or `operator`

- [ ] **B1** newly added Arrow Vector / FieldVector is closed in try-with-resources or try-finally
- [ ] **B2** Velox Session / QueryResult is closed correctly
- [ ] **B3** resources allocated in Operator open() are released in close()/dispose()
- [ ] **B4** C++ new/malloc/allocate is paired with delete/free/release
- [ ] **B5** resources are still released on exception paths (check whether catch blocks close them)

> Any violation of B1/B2/B3/B4 → CRITICAL; B5 → HIGH

### C. Exception handling

**Trigger**: tags include `exception`

- [ ] **C1** no empty catch blocks (`catch` followed directly by `}` or only a comment)
- [ ] **C2** no catching of `Exception` where a specific exception type is appropriate
- [ ] **C3** catch blocks do not swallow exceptions that should propagate
- [ ] **C4** finally blocks contain no unprotected logic that can throw

> C1 → CRITICAL, verdict fail; C2/C3 → HIGH

### D. Serialization compatibility

**Trigger**: tags include `json-serde` or `rexcall`

- [ ] **D1** new fields in JSON serialization classes are appended at the end of the class
- [ ] **D2** no existing field is deleted or renamed
- [ ] **D3** RexCallConverterFactory mappings are append-only

> Any violation → CRITICAL, verdict fail

### E. Operator lifecycle

**Trigger**: tags include `operator`

- [ ] **E1** open() calls super.open()
- [ ] **E2** close() calls super.close()
- [ ] **E3** close() is idempotent — repeated calls do not throw
- [ ] **E4** dispose() releases anything open()/close() left unreleased

> E1/E2 → HIGH; E3/E4 → MEDIUM

### F. C++ memory safety

**Trigger**: tags include `pointer`, or the change touches `.cpp`/`.h` files

- [ ] **F1** local variables are initialized on all branches before use
- [ ] **F2** pointers / dynamic_cast results are null-checked before use
- [ ] **F3** array/vector accesses validate the index range
- [ ] **F4** released resources are nulled/reset
- [ ] **F5** no sizeof(pointer) used where sizeof(array) was meant

> F1/F2/F3 → CRITICAL; F4/F5 → MEDIUM

### G. Numeric safety

**Trigger**: tags include `numeric`

- [ ] **G1** division/modulo validates a non-zero divisor
- [ ] **G2** array index / memory length computations guard against overflow
- [ ] **G3** signed integer arithmetic guards against overflow
- [ ] **G4** magic numbers are replaced by named constants

> G1/G2/G3 → CRITICAL; G4 → MEDIUM

### H. Import discipline

**Trigger**: tags include `import`, or any Java change

- [ ] **H1** no wildcard imports (`import .*`)
- [ ] **H2** import order follows the project convention

> H1/H2 → MEDIUM (Spotless auto-fixes at build time; non-blocking)

### I. General quality

**Trigger**: all changes

- [ ] **I1** no dead code in the changed lines (declared, never used)
- [ ] **I2** no unused imports/variables/parameters in the changed lines
- [ ] **I3** logs do not emit sensitive information
- [ ] **I4** modified files stay within the SPEC/design scope and the task's allowed-modification scope

> I4 → CRITICAL, verdict fail; I1/I2 → LOW; I3 → HIGH
