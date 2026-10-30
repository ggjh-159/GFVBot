#!/usr/bin/env bash
# Copyright (c) Contributors to the GFVBot project.
# Licensed under the Apache License, Version 2.0.
#
# Pull the full review conversation of a PR and archive it as markdown,
# grouped by review (not global-timeline) so each review's body stays
# attached to its line comments.
#
# Usage: pull-reviews.sh <owner/repo> <pr-number> [output-file]
#   GITHUB_TOKEN (optional) raises the rate limit from 60/h (anonymous);
#   otherwise ~/.netrc is consulted via --netrc-optional.
#
# Output layout:
#   # <repo> PR #<n> review archive
#   ## Review: <state> (by <login>, <time>)        <- one per review
#      <review body>
#      ### [time] <login> @ <path>:<line>          <- that review's line comments
#   ## Standalone line comments (no parent review)
#   ## Conversation                                <- issue comments, time order

set -euo pipefail

REPO="${1:?usage: pull-reviews.sh <owner/repo> <pr-number> [output-file]}"
PR="${2:?missing pr number}"
OUT="${3:-$(echo "$REPO" | tr '/' '-')-pr${PR}-review-archive.md}"

AUTH=(--netrc-optional)
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  AUTH+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT

api() {
  local url="$1" page="$2" attempt=0
  while true; do
    local resp body http
    resp=$(curl -s -w '\n%{http_code}' "${AUTH[@]}" \
      -H "Accept: application/vnd.github+json" \
      "${url}?per_page=100&page=${page}")
    http="${resp##*$'\n'}"
    body="${resp%$'\n'*}"
    if [[ "$http" == "200" ]]; then
      printf '%s' "$body"
      return 0
    fi
    attempt=$((attempt + 1))
    if { [[ "$http" == "403" || "$http" == "429" ]] && [[ $attempt -lt 3 ]]; }; then
      sleep $((5 * attempt))
      continue
    fi
    echo "HTTP $http on $url (attempt $attempt)" >&2
    return 1
  done
}

collect() {
  local endpoint="$1" dest="$2" page=1 batch count
  : > "$dest"
  : > "$dest.items"
  echo "[" > "$dest"
  local first=1
  while true; do
    batch=$(api "https://api.github.com/repos/${REPO}/${endpoint}" "$page") || return 1
    count=$(python3 -c "import json,sys; print(len(json.loads(sys.stdin.read())))" <<<"$batch")
    if [[ $first -eq 1 ]]; then
          printf '%s' "${batch:1:-1}" >> "$dest"
          first=0
    else
          printf '%s' ",${batch:1:-1}" >> "$dest"
    fi
    [[ $count -lt 100 ]] && break
    page=$((page + 1))
  done
  echo "]" >> "$dest"
}

collect "pulls/${PR}/reviews" "$TMPD/reviews.json"
collect "pulls/${PR}/comments" "$TMPD/lines.json"
collect "issues/${PR}/comments" "$TMPD/conv.json"

OUT="$OUT" python3 - "$TMPD/reviews.json" "$TMPD/lines.json" "$TMPD/conv.json" "$REPO" "$PR" <<'PYEOF'
import json, os, sys

reviews = json.load(open(sys.argv[1]))
lines = json.load(open(sys.argv[2]))
conv = json.load(open(sys.argv[3]))
repo, pr = sys.argv[4], sys.argv[5]
out = os.environ['OUT']

def t(iso):
    return iso.replace('T', ' ').replace('Z', ' UTC') if iso else '?'

by_review = {}
for c in lines:
    by_review.setdefault(c.get('pull_request_review_id'), []).append(c)

parts = [f"# {repo} PR #{pr} review archive", "",
         f"> Pulled: {__import__('datetime').datetime.utcnow():%Y-%m-%d %H:%M UTC}", ""]

for r in reviews:
    login = r['user']['login']
    state = r['state']
    parts.append(f"## Review: {state} (by {login}, {t(r.get('submitted_at'))})")
    if r.get('body'):
        parts += ['', r['body']]
    for c in sorted(by_review.get(r['id'], []), key=lambda x: x['created_at']):
        loc = f"{c.get('path')}:{c.get('line') or c.get('original_line')}"
        parts += ['', f"### [{t(c['created_at'])}] {c['user']['login']} @ `{loc}`", '', c['body']]
    parts.append('')

orphan = by_review.get(None, [])
if orphan:
    parts.append('## Standalone line comments (no parent review)')
    for c in sorted(orphan, key=lambda x: x['created_at']):
        loc = f"{c.get('path')}:{c.get('line') or c.get('original_line')}"
        parts += ['', f"### [{t(c['created_at'])}] {c['user']['login']} @ `{loc}`", '', c['body']]
    parts.append('')

if conv:
    parts.append('## Conversation')
    for c in sorted(conv, key=lambda x: x['created_at']):
        parts += ['', f"### [{t(c['created_at'])}] {c['user']['login']}", '', c['body']]
    parts.append('')

open(out, 'w').write('\n'.join(parts))
print(f"archived: {out}", file=sys.stderr)
PYEOF
