#!/usr/bin/env python3
"""changelog_diff.py — reduce two changelog captures to their final result
sets and compare them exactly.

Usage: changelog_diff.py <native-out> <gfv-out>

Input: files of print-connector rows, one per line, in the form
    +I[a, b, c]   -U[...]   +U[...]   -D[...]
Lines not matching FLAG[payload] are ignored (log noise).

Method: multiset fold — +I/+U add the payload row, -U/-D remove it
(retraction rows carry the exact old value). Row order is not compared.
See references/changelog-semantics.md for why this is exact.

Exit 0 on exact match, 1 on any difference. Report goes to stdout in a
paste-into-TEST_REPORT friendly form.
"""
import collections
import re
import sys

ROW = re.compile(r'^([-+][IUD])\[(.*)\]$')


def fold(path):
    """Return (final multiset, stats, fold errors)."""
    final = collections.Counter()
    stats = collections.Counter()
    errors = []
    with open(path, encoding='utf-8', errors='replace') as fh:
        for lineno, line in enumerate(fh, 1):
            m = ROW.match(line.rstrip('\n'))
            if not m:
                continue
            flag, payload = m.groups()
            stats[flag] += 1
            if flag in ('+I', '+U'):
                final[payload] += 1
            else:  # -U, -D withdraw the exact row they carry
                if final[payload] <= 0:
                    errors.append(f'{path}:{lineno}: {flag} withdraws row '
                                  f'never present: [{payload}]')
                final[payload] -= 1
                if final[payload] == 0:
                    del final[payload]
    return final, stats, errors


def main():
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    a_path, b_path = sys.argv[1:3]
    a, a_stats, a_err = fold(a_path)
    b, b_stats, b_err = fold(b_path)

    print(f'native: {sum(a_stats.values())} rows folded -> '
          f'{sum(a.values())} final rows  '
          f'(flags: {", ".join(f"{k}={v}" for k, v in sorted(a_stats.items())) or "none"})')
    print(f'gfv:    {sum(b_stats.values())} rows folded -> '
          f'{sum(b.values())} final rows  '
          f'(flags: {", ".join(f"{k}={v}" for k, v in sorted(b_stats.items())) or "none"})')
    for e in a_err + b_err:
        print(f'FOLD ERROR: {e}')
    if a_err or b_err:
        print('RESULT: MISMATCH (malformed changelog — fold errors above)')
        return 1

    missing = a - b  # in native, not in gfv
    extra = b - a    # in gfv, not in native
    if not missing and not extra:
        print(f'RESULT: MATCH ({sum(a.values())} rows, exact)')
        return 0

    print('RESULT: MISMATCH')
    for row, n in sorted(missing.items()):
        print(f'  missing in gfv  (x{n}): [{row}]')
    for row, n in sorted(extra.items()):
        print(f'  extra in gfv    (x{n}): [{row}]')
    print('  note: multiset compare — duplicate counts count; '
          'field formatting differences are real mismatches')
    return 1


if __name__ == '__main__':
    sys.exit(main())
