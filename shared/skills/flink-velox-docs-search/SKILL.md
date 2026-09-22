---
name: flink-velox-docs-search
description: Locate development material for the GFV stack — local source and docs first, official Flink and Velox documentation as fallback — with strict context economy.
---

# flink-velox-docs-search

## Purpose

Answer "where is X documented / implemented" for the GFV stack without flooding the context window: search the local workspace first, fall back to official online documentation only when the local tree cannot answer.

## Context economy rules

- Search first, read fragments: grep for the keyword to locate the relevant section, then read only the hit ranges with offset/limit.
- Cap results at three: return at most the three most relevant hits, each as `path:line — one-sentence summary`. Do not paste document bodies.
- Index files under `references/` are for locating, not for loading; never read them whole into context.
- Online queries stay narrow: one question per query, extract the key passage only.

## Local resources, in the order to try

1. Source code under `<workspace>/repos/` — the ultimate ground truth. See `references/module-map.md` for the repo-to-responsibility map and the branch baselines.
2. The target project's own documentation tree — design notes, feature investigations, and troubleshooting records live there and often answer project-specific questions faster than upstream docs.
3. Velox upstream docs rendered from the velox repo (developers' guide, operators, expressions, functions reference) — grep them inside the repo before going online.

## Online fallback

Use when the local tree has nothing:

- Flink 1.19 documentation — operator semantics, state backends, watermarks, SQL
- Velox documentation on GitHub — operators, aggregate and scalar functions, memory, spilling
- Arrow documentation — vector layout and interop details for bridge work

Prefer a targeted search (`site:` scoping, exact symbol names) over landing pages.

## Output contract

Every answer lists where it came from: local hits as `path:line — summary`, online hits with the URL and the one passage that answers the question. If nothing is found, say so explicitly instead of paraphrasing something adjacent.
