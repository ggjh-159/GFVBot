# Upstream issue/PR draft templates — routing and discipline

> When a task changes the velox / velox4j / gluten repositories, the retro stage drafts community issues and PRs from the templates in this unit into `tasks/<task-name>/upstream/` of the target project. Nothing is filed until the user gives final confirmation; agents never submit issues or PRs on their own.

## Template selection

| Target repository | Issue | PR |
|---|---|---|
| apache/incubator-gluten | gluten-issue-bug.md / gluten-issue-enhancement.md | gluten-pr.md |
| facebookincubator/velox | velox-issue-bug.md / velox-issue-enhancement.md | velox-pr.md |
| bigo-sg/velox4j | same as velox (no official templates; velox conventions) | same as velox |

## Issue discipline

- Exactly one issue per expression (or operator), never duplicated across repositories: gluten changed → gluten templates; otherwise → velox/velox4j templates (when both change, file against velox — where the semantics live).
- New function, new operator, or capability extension → enhancement; behavioral defect → bug.
- File in English; keep field labels exactly as the community templates define them.

## PR discipline

- One PR draft per changed repository, following that repository's template.
- gluten: title prefixed `[VL]`; body links the issue via `Fixes #<issue-id>`; fill in the generative-AI section truthfully (`Generated-by:` or `No`) per ASF policy.
- Test descriptions must match the actual results in TEST_REPORT / VERIFY.md.

## Template sources

- gluten: apache/incubator-gluten `.github/ISSUE_TEMPLATE/bug.yml`, `enhancement.yml`, and `.github/PULL_REQUEST_TEMPLATE`.
- velox: facebookincubator/velox `.github/ISSUE_TEMPLATE/bug.yml` and `enhancement.yml`; velox ships no PR template file — velox-pr.md is the minimal community-convention structure.
