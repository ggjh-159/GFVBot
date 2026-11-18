---
name: flink-velox-stateful-design-analysis
description: Mechanism-level analysis procedure for stateful-operator DESIGN docs — with an approved SPEC as the contract, produces per-section material covering honest grading of the translation chain, reuse dispositions, formula positioning, the alignment list, limitations, and pending decisions, every conclusion carrying a one-line basis.
---

# flink-velox-stateful-design-analysis

## Purpose

The design-stage mechanism-level analysis procedure for the architect: with an approved SPEC as the contract, make the "how" analysis concrete and produce anchored material for every DESIGN.md section. Feasibility determination and acceptance wording were pinned down at spec stage (flink-velox-stateful-spec-analysis); this skill does not repeat spec-side analysis. Writing and curating DESIGN.md belongs to the architect.

## Input contract

Required: `tasks/<task-name>/architect/SPEC.md` (SPEC review passed). Optional: `docs/gfvbot/shared/stateful-operator-implementation.md` (the implementation contract, the primary technical reference), reviewer feedback (rework rounds). All retrieval goes through composed flink-velox-docs-search calls (scope limiting, relevance filtering, and context-frugality rules carry over in full); this skill never searches online on its own.

## Analysis discipline

- One basis per conclusion: a source location, a precedent, or a ruling date; assertions without a basis are not accepted.
- Verify the current state, never infer it: "already exists / zero-change" claims may be written only after verifying them in source, with file:line.
- Reuse disposition enumeration: a disposition for every facility (reuse directly / reuse with modification / build new / not adopted); facilities not adopted are written down too, with reasons, so later readers do not re-survey them.
- Non-default paths carry a complete mechanism: EMIT and other non-default configuration paths get their full mechanism (metadata source, emit decision, state attachments) — never just "not supported yet".
- Mechanism choices that deviate from Flink's structure (swapping storage / channel / indexing) are escalated to pending decisions, never made silently.

## Procedure

### Step 1 — mechanism-level semantic deepening

Distill the target operator's mechanism facts from the Flink sources, seeding the §5 alignment list:

- Selection table: input shape / operator variant → processor / state shape → trigger.
- Three dataflow streams: the record / watermark / timer paths (processElement → state; processWatermark → fire → propagation).
- The changelog determination chain: which flag decides an updating stream + a scenario table (scenario / trigger / RowKind / state action).
- A key behavior-points list, each with file:line — late-data handling, time zones, empty windows, output ahead of watermark propagation, and so on; the items must line up with the SPEC's behavior specification.

### Step 2 — verify the GFV current state across the three stages

Verify each translation-chain stage and grade it honestly (complete / half-done / missing; half-done = dead code / hard-coding / NYI, each evidenced with file:line):

- Gluten shadow translation: whether `StatefulPlanner#transformStatefulOperators` already has a same-kind branch; ExecNode shadow-override status.
- velox4j beans + C++ serde: existing node classes in `StatefulPlanNode.h` and the serde triple.
- C++ operators: the status of `experimental/stateful` and what the `GroupAggregator` exemplar offers.

### Step 3 — reuse dispositions and formula positioning

- Reuse disposition enumeration: operator shell / KeySelector / state handles / serializers, each with a disposition and notes — lands in §2.
- Formula positioning: new operator = the `GroupAggregator` skeleton + the delta, one sentence on where the delta concentrates — lands in §1.
- Contract-matching placement: state handle selection, the initializeStateBackend five steps, and the addInput seven steps mapped item by item onto this operator — lands in §3.

### Step 4 — execution flow and the alignment list

- Seven-step pattern placement: input → probe → state resolution → business logic → changelog → output, item by item with anchors — lands in §5.
- Alignment list: the step-1 behavior points checked one by one (Flink behavior + this design's handling + alignment grade); the grades are exact (same formula, same mechanism) / equivalent (different mechanism, same semantics, with an equivalence argument) / consistent (same as an existing trimming precedent) / phased (mechanism in the design, implementation deferred to a later stage) / trimmed (must carry a ruling basis).
- Non-default paths get their own entries with a complete mechanism — lands in §5/§6.

### Step 5 — limitations, pending decisions, and the test surface

- Limitations list: fail-loud exclusions numbered one by one, the TODO naming which capability owns the resolution — a limitation is an open problem, not final semantics — lands in §9.
- Pending decisions: only choices deviating from Flink's structure at the mechanism level or affecting contract wording; per item, a self-contained background + an option-comparison table (dimensions × options) + a recommendation + a one-line basis — lands in §10.
- nexmark touch surface: which queries land on this operator, and existing suites usable as e2e baselines — lands in §7.

## Output contract

Material is organized per the DESIGN template's sections, every fact carrying an anchor (`path#Class/method` or `path:line`), conclusions noting their basis (source / precedent / ruling date). A point that cannot be verified is reported as "not found", never inferred from adjacent content. Material is presented only for the architect to curate into DESIGN.md; this skill writes no files and does not author the DESIGN. Pending decisions are written by the architect into §10, ruled item by item at user gate 1, and written back in place.
