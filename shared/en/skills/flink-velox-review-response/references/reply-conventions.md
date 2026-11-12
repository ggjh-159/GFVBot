# Reply conventions (review-response templates)

Replies to reviewers follow a fixed skeleton — thanks first, then itemized responses with commit references. Generated drafts land in `tasks/<task-name>/upstream/review-response/replies/` and require per-post user confirmation before anything is posted (see SKILL.md's "Human gates" — nothing outbound ships unconfirmed). Replies are in English; Chinese analysis notes have no fixed location.

## Skeleton of every reply

```
@<reviewer> Thanks for the review! <one-line summary of what was addressed>

- **<item 1>**: <what was done> — pushed in <sha8>.
- **<item 2>**: <what was done> — pushed in <sha8>.
- **<suggestion taken without code change>**: noted, <reason>.
```

## must-fix

Respond to the exact defect the reviewer described, mirror their wording, and name the test that pins the fix:

```
- **<the flagged issue>**: fixed in <sha8> — <one sentence of what changed>.
  Verified by <added/updated test name>.
```

## decision-needed (semantic divergence)

The agent never picks a side — the reply presents the user's ruling with its evidence:

```
- **<the divergence>**: we keep <chosen option> as an intentional deviation.
  <one sentence of evidence>. Documented at <code location> and pinned by
  <test names>.
```

## evidence-first (reviewer asks to confirm a behavior)

Run the experiment before drafting. The reply opens with the verdict, then the evidence chain (a source anchor showing the mechanism → an empirical artifact such as an EXPLAIN physical plan keeping the call un-folded, with the actual output quoted → supporting detail such as the two runtime granularities and which one applies), closing with what it means for the PR — no change needed / changed in `<sha8>`.

## wording / comment-only

```
- **<the wording issue>**: reworded in <sha8>; comment-only change, no code change.
```

## Claim vs implementation mismatch (testing-section claims)

Two legal resolutions — pick one, never leave the claim standing unfixed: cover it in code (preferred; the reply cites both the fix and the test) or drop the claim (the reply states it is removed from the description — the PR does not add that support).

## Where replies land

Default: one consolidated reply on the review's conversation thread (covering all items); points that need the surrounding code context to read additionally get an inline reply on their line comment. When branch history moved (merge-based sync), attach the old → new commit mapping so the reviewer can find the anchored content.

## PR description updates

Vehicle: the API `PATCH /repos/{owner}/{repo}/pulls/{n}` (body replaced wholesale) or the web UI — same confirmation gate as comment posts. Before patching: fetch the current description, produce the new version, show the diff for confirmation. The accompanying comment notes "PR description updated accordingly". Major rewrites keep an `<repo>-pr<N>-description.old.md` snapshot under `descriptions/` for claim-evolution traceability.
