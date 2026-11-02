# Dependency cascade across velox / velox4j / gluten

Reference for the review-response skill: how refs, hashes, and repo URLs cascade when any repo in the chain advances. All rules below were proven in live multi-round three-repo review chains.

## The chain

```
velox (bigo-sg)  ──velox-ref.txt──▶  velox4j (bigo-sg)  ──CI pin──▶  gluten (apache)
```

velox4j builds against a pinned velox commit: `src/main/cpp/velox-ref.txt` (commit SHA) + `velox-ref-hash.txt` (MD5 of that commit's codeload zip); the two files change together. gluten does not pin velox directly; its CI (`flink.yml`) clones a velox4j branch at a specified commit and builds the whole stack from there.

## Trigger matrix

| Event | velox4j action | gluten action |
|---|---|---|
| velox branch gains commits (PR still open) | update velox-ref.txt/hash to the new fork head | update the CI pin to the new velox4j commit |
| velox PR merges upstream | ref → upstream merge head; repo URL fork → upstream; recompute hash from the upstream codeload | wait — no pin-jumping (see timing rule) |
| velox4j PR merges upstream | — | clone line switches to the bigo-sg branch + pin to the merge head |

## Intermediate-state timing rule

While the velox4j pin PR is still under review, its head commit keeps moving. Do **not** update gluten's reference for every velox4j commit — wait until velox4j merges, then switch gluten once, straight to the upstream end state. This avoids pin-chain churn (observed in practice: intermediate pin updates were superseded by merges within days).

## md5 computation constraint

`velox-ref-hash.txt` is the MD5 of `https://github.com/<org>/velox/archive/<full-sha>.zip`. The codeload zip only exists for **pushed** commits, so the operation order is fixed: push velox, compute the hash, then update velox4j. Example (switching back to upstream after a merge):

```bash
M=$(git -C repos/velox rev-parse <upstream-merge-head>)
MD5=$(curl -sL "https://github.com/bigo-sg/velox/archive/${M}.zip" -o /tmp/v.zip \
      && md5sum /tmp/v.zip | awk '{print $1}')
cd repos/velox4j   # on the pin branch
echo "$M"   > src/main/cpp/velox-ref.txt
echo "$MD5" > src/main/cpp/velox-ref-hash.txt
git add -u && git commit -m "Point the velox ref at the merged upstream revision"
```

## Post-merge URL regression to upstream

While a feature PR is in flight, velox4j's CMakeLists points at the personal fork (the `VELOX_REPO` and `VELOX_SOURCE_URL` lines hold the fork's `<owner>/velox`). Once the velox PR merges, switch both lines back to the upstream repo — the fork detour is no longer needed:

```bash
sed -i 's/<fork-owner>\/velox/bigo-sg\/velox/' src/main/cpp/CMakeLists.txt   # both lines
```

gluten's CI routing follows the same pattern: in `.github/workflows/flink.yml` and `gluten-flink/docs/Flink.md`, the clone line moves from the fork's pin branch to `-b gluten-20260829 https://github.com/bigo-sg/velox4j.git`, and the `git reset --hard <sha>` target moves to the velox4j merge head.

## Local format toolchain (velox repo)

The toolchain for `make format-fix CHECK_BASE=gluten-20260829` (pip-installed, matching the CI's Ubuntu 24.04 apt versions): regex, black, pyyaml, cmakelang==0.6.13, clang-format 18. check.py refuses to run while files carry unstaged edits — `git add` before `format-fix`.

## Cross-branch impact check

After any repo merges, check whether other in-flight branches diverged from the advanced upstream. Sync affected branches with **merge, not rebase** — merge preserves the original commit history and the review anchors (anchor-protection rules in SKILL.md Stage 4).
