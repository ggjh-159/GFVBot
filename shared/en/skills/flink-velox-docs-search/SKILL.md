---
name: flink-velox-docs-search
description: Locate development material for the GFV stack — installed docs and local source first, official Flink and Velox documentation as fallback — with input-side scope limiting, relevance filtering, and strict context economy.
---

# flink-velox-docs-search

## Purpose

Answer "where is X documented / implemented" for the GFV stack without flooding the context window: search the installed docs and the local workspace first, fall back to official online documentation only when the local tree cannot answer.

## Input: scope limiting

The caller declares the search scope on the input side; this skill never widens it on its own:

- Default scope = the docs units bound to the calling agent (the `docs:` list in the agent frontmatter), mapping to directories installed under `docs/gfvbot/` in the target project.
- When an explicit list of units is passed, search only those units; stepping outside the bound scope requires the caller to say so explicitly.

## Local resources, in the order to try

1. Docs units installed under the target project's `docs/gfvbot/` — GFV-distilled architecture, expression cards, internals deep-dives, verification manuals; the first landing point. Grep within the limited scope.
2. Source code under `<workspace>/repos/` — the ultimate ground truth. See `references/module-map.md` for the repo-to-responsibility map and the branch baselines.
3. The target project's own documentation tree — design notes, feature investigations, and troubleshooting records live there and often answer project-specific questions faster than upstream docs.
4. Velox upstream docs rendered from the velox repo (developers' guide, operators, expressions, functions reference) — grep them inside the repo before going online.

## Relevance evaluation

Evaluate hits before reporting; keep only the valuable ones:

- Three signals set relevance: a direct hit on a section heading or card name is strongest, dense keyword hits in the body come second, glancing term matches are weakest — glancing hits are discarded outright.
- Keep at most three entries, each as `path:line — one sentence on what it answers of the question`.
- When unsure whether a hit is worth expanding, give only the path and a one-sentence summary and let the caller decide whether to read — never paste document bodies unprompted.

## Context economy rules

- Search first, read fragments: grep for the keyword to locate the relevant section, then read only the hit ranges with offset/limit.
- Index files under `references/` are for locating, not for loading; never read them whole into context.
- Online queries stay narrow: one question per query, extract the key passage only.

## Online fallback

Use when the local tree has nothing:

- Flink 1.19 documentation — operator semantics, state backends, watermarks, SQL
- Velox documentation on GitHub — operators, aggregate and scalar functions, memory, spilling
- Arrow documentation — vector layout and interop details for bridge work

Prefer a targeted search (`site:` scoping, exact symbol names) over landing pages.

## Output contract

Every answer lists where it came from: local hits as `path:line — summary`, online hits with the URL and the one passage that answers the question. If nothing is found, say so explicitly instead of paraphrasing something adjacent.
