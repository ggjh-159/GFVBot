---
name: flink-velox-stateful-spec-analysis
description: Feasibility analysis procedure for stateful-operator SPECs — two-tier determination (semantic mapping × infrastructure supply), a matrix lookup yielding the four-way conclusion, constraints only tighten and are always recorded item by item, and per-SPEC-section material with anchors.
---

# flink-velox-stateful-spec-analysis

## Purpose

The spec-stage feasibility analysis procedure for the architect: starting from the task description, determine whether — and in what sense — the target operator is feasible on the GFV stack, and gather anchored factual material for every SPEC section. This skill produces material and conclusions; writing and curating SPEC.md belongs to the architect.

## Input contract

Required: a task description (target operator name + expected semantics). Optional: user constraints, `tasks/<task-name>/TASK_STATE.md`. All retrieval goes through composed flink-velox-docs-search calls (its scope limiting, relevance filtering, and context-frugality rules carry over in full); this skill never searches online on its own.

## Determination dimensions

**A — semantic mapping** (Flink operator semantics vs. the velox status quo, verified per behavior point):

| Tier | Meaning |
|---|---|
| A1 exact match | velox already has a facility with the same semantics; directly usable |
| A2 partial match, compensable in-stack | the semantics have a gap compensable within the stack (e.g. keyed semantics via a non-keyed transformation + KeySelector) |
| A3 upstream capability needed | closing the gap depends on upstream repos (velox core, the Flink distribution, the community) |
| A4 no support | the semantics have no implementation path in this stack |

**B — infrastructure supply** (an inventory of existing facilities within the stack boundary):

| Tier | Meaning |
|---|---|
| B1 direct reuse | state handles, the operator shell, serde, and plan mirrors all exist |
| B2 extension-point addition | additions within existing extension points (a StatefulPlanNode.h node class, a planner dispatch branch, a gluten shadow override) |
| B3 framework-mechanism change | changes to the framework proper (StatefulTask, the StatefulOperator shell, the state-backend mechanism) |

**Stack boundary**: in-stack = velox/experimental/stateful + velox/functions/flinksql + the entire velox4j repo + the gluten-flink module; everything else (velox core, gluten's non-flink parts, the Flink distribution, community merges still pending) is upstream.

**Conclusion matrix** (rows A × columns B; the lookup yields the conclusion):

| A\B | B1 | B2 | B3 |
|---|---|---|---|
| A1 | feasible | feasible | feasible with constraints |
| A2 | feasible with constraints | feasible with constraints | feasible with constraints |
| A3 | feasible with upstream dependency | feasible with upstream dependency | feasible with upstream dependency |
| A4 | not feasible | not feasible | not feasible |

## Adjustment rules

1. The matrix cell is the floor; constraints only tighten. The matrix conclusion reflects only the two dimensions; a task-level hard constraint found during verification (e.g. appendOnly sources only, a state-size ceiling) raises the conclusion one notch (feasible → feasible with constraints). Only tightening is allowed — never self-downgrade on the grounds of "hard to implement".
2. Accompanying constraints are recorded item by item regardless of tier. Whatever tier the conclusion lands on, its accompanying constraints go into the feasibility material's constraint list — never omitted because "the strictest tier is already reached" (under an upstream-dependency conclusion, the heap-memory ceiling while waiting remains a valid constraint).

## Procedure

### Step 1 — verify semantics, set tier A

- List the target operator's behavior points against Flink semantic anchors (`StreamExecXxx` + the Flink 1.19 docs): trigger cadence, state access, watermark/timer behavior, output and changelog.
- Verify the velox status quo per point: docs-search locates `stateful-operator-implementation.md` and `internals/stateful-operator.md`, then anchors are taken from the repos/velox sources.
- One line per point: point — status quo — anchor; set tier A from these lines, noting the determination basis.

### Step 2 — verify infrastructure, set tier B

- Inventory the facilities in the four zones of the stack boundary: state handles (`state/HeapKeyedStateBackend.h`), the operator shell and exemplar (`StatefulOperator.h`, `agg/GroupAggregator`), plan nodes and serde (`StatefulPlanNode.h`), Java mirrors and gluten wiring (velox4j's `plan/`, the gluten-flink planner).
- One line per zone: facility — reuse / extend / change-framework — anchor; set tier B from these lines.

### Step 3 — look up the matrix, conclude

- Look up the conclusion matrix with A×B.
- Apply adjustment rule 1: task-level hard constraints raise the notch.
- Apply adjustment rule 2: assemble the accompanying constraint list, each item with an evidence anchor.

### Step 4 — material for the remaining sections

Feasibility material came out of steps 1-3; gather anchored facts for the remaining SPEC sections:

- Goal and scope: the one-line goal compresses the task wish through the step-1 semantic points; in-scope takes the facility layers step 2 will touch; every out-of-scope exclusion carries a reason + evidence anchor (pointing to an A-tier gap or the constraint list) — no exclusion without grounds.
- Interface spec: input/output types, value shape (RowContainer row / single value), serde registration-name candidates — anchors from existing operators of the same kind.
- Behavior spec: where the five-step/seven-step lifecycle sketches onto this operator, default watermark cascading — anchors from the contract doc and the GroupAggregator exemplar.
- Acceptance criteria and verification plan: existing suites usable as baselines (GroupAggregatorTest, nexmark queries, e2e dual-run comparison) — anchors from test files and the query library.
- The task section (task-name/date/source) is dispatch metadata, transcribed verbatim by the architect; this skill produces nothing for it.

## Output contract

Material is organized per the SPEC template's sections, every fact carrying an anchor (`path#Class/method` or `path:line`); the conclusion line notes the matrix tiers (e.g. `feasible with constraints (A2×B1)`). A point that cannot be verified is reported as "not found" — never inferred from adjacent content. Material is presented only for the architect to curate into SPEC.md; this skill writes no files and does not author the SPEC.
