#!/usr/bin/env python3
"""perf_report.py — compare nexmark metric captures from native Flink and
GFV runs and emit the fixed performance report.

Usage: perf_report.py <native-dir> <gfv-dir>

Input: capture directories produced by run-perf.sh. Files are named
    <qNN>.p<P>.r<0|1>.out    (r1 = pipeline.object-reuse=true, native only)
each holding the runner's "Nexmark Results" summary table (pipe-separated
rows; the events mode carries Events Num / Time(s) / Throughput, the tps
mode only Throughput). Pairs are keyed by (query, p) across the r0/r1/gfv
sides.

Output: rendered from the skill's fixed template
(references/report-template.md, one directory up from this script), which
carries all wording; this script only substitutes three placeholders with
ASCII data — the throughput rows (GFV/native ratios against both reuse
baselines), the runtime rows, and the unpaired-capture list. Row notes use
the codes documented in the template legend: nc:events marks a
not-comparable row (configured event count differs across sides), '-'
marks a missing side. The table's Cores column is measured CPU usage, not
a setting, so it is not compared.

No pass/fail verdict is emitted — performance judgement belongs to the
reader. Exit 0 when at least one pair was compared, 1 otherwise.
"""
import re
import sys
from pathlib import Path

NAME = re.compile(r'^(.+)\.p(\d+)\.r([01])\.out$')


def num(cell):
    """'1,980,198 r/s' -> 1980198.0; None when no number is present."""
    s = cell.strip().replace(',', '')
    s = re.sub(r'(?i)\s*r/?s\s*$', '', s)
    m = re.search(r'-?\d+(?:\.\d+)?', s)
    return float(m.group()) if m else None


def parse_table(path):
    """Return {query: {'throughput': .., 'time': .., 'events': ..}} from one
    capture file (None values when the column is absent)."""
    metrics = {}
    header = None
    for line in Path(path).read_text(encoding='utf-8', errors='replace').splitlines():
        if not line.lstrip().startswith('|'):
            continue
        cells = [c.strip() for c in line.strip().strip('|').split('|')]
        if header is None:
            if 'Query' in cells:
                header = cells
            continue
        row = dict(zip(header, cells))
        name = row.get('Query')
        if not name:
            continue
        entry = {'throughput': None, 'time': None, 'events': None}
        for key, col in (('throughput', 'Throughput'),
                         ('throughput', 'Throughput (r/s)'),
                         ('time', 'Time(s)'), ('events', 'Events Num')):
            if col in row and entry[key] is None:
                entry[key] = num(row[col])
        metrics[name] = entry
    return metrics


def load_dir(d):
    """Return ({(query, p): {'r0': entry, 'r1': entry}}, notes) built from
    <q>.p<N>.r<x>.out files. A note is added when the file's table holds
    rows but none named after the file's query — a mislabelled capture
    must not pass silently as 'all dashes'."""
    caps, notes = {}, []
    for f in sorted(d.glob('*.out')):
        m = NAME.match(f.name)
        if not m:
            continue
        q, p, r = m.group(1), int(m.group(2)), m.group(3)
        table = parse_table(f)
        entry = table.get(q)
        if entry is None and table:
            notes.append(f'- {f.name}: table has no row named "{q}" '
                         f'(rows: {", ".join(table)})')
        caps.setdefault((q, p), {})[f'r{r}'] = entry or {}
    return caps, notes


def qkey(key):
    q, p = key
    digits = re.sub(r'\D', '', q)
    return (int(digits) if digits else 0, q, p)


def fmt(v):
    return f'{v:,.0f}' if v is not None else '-'


def ratio(a, b):
    if not a or not b:
        return '-'
    return f'{a / b:.2f}'


def tsec(e):
    v = e.get('time')
    return f'{v:.1f}' if v is not None else '-'


def main():
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    native_dir, gfv_dir = (Path(d) for d in sys.argv[1:3])
    for d in (native_dir, gfv_dir):
        if not d.is_dir():
            print(f'not a directory: {d}', file=sys.stderr)
            return 2

    native, n_notes = load_dir(native_dir)
    gfv, g_notes = load_dir(gfv_dir)

    t_rows, time_rows, unpaired = [], [], n_notes + g_notes
    pairs = 0
    for key in sorted(set(native) | set(gfv), key=qkey):
        q, p = key
        n, g = native.get(key), gfv.get(key)
        if not n or not g:
            side = 'native' if not n else 'gfv'
            unpaired.append(f'- {q}.p{p}: missing on the {side} side')
            continue
        n0, n1, g0 = n.get('r0') or {}, n.get('r1') or {}, g.get('r0') or {}
        if n.get('r1') is None:
            unpaired.append(f'- {q}.p{p}: native r1 capture missing (ratio vs r1 is "-")')
        pairs += 1

        notes = []
        events = [e.get('events') for e in (n0, n1, g0) if e.get('events') is not None]
        if len(set(events)) > 1:
            notes.append('nc:events')
        note = ','.join(notes)

        t_rows.append(f'| {q} | {p} | {fmt(n0.get("throughput"))} | '
                      f'{fmt(n1.get("throughput"))} | {fmt(g0.get("throughput"))} | '
                      f'{ratio(g0.get("throughput"), n0.get("throughput"))} | '
                      f'{ratio(g0.get("throughput"), n1.get("throughput"))} | {note} |')
        time_rows.append(f'| {q} | {p} | {tsec(n0)} | {tsec(n1)} | {tsec(g0)} | {note} |')

    template_path = Path(__file__).resolve().parent.parent / 'references' / 'report-template.md'
    if not template_path.is_file():
        print(f'report template not found: {template_path}', file=sys.stderr)
        return 1
    if pairs == 0:
        print('no (query, p) pair found across the two capture dirs '
              f'({native_dir}, {gfv_dir})', file=sys.stderr)
        return 1

    report = template_path.read_text(encoding='utf-8')
    report = report.replace('{{THROUGHPUT_TABLE}}', '\n'.join(t_rows))
    report = report.replace('{{TIME_TABLE}}', '\n'.join(time_rows))
    report = report.replace('{{UNPAIRED}}', '\n'.join(unpaired) or '(none)')
    print(report, end='')
    return 0


if __name__ == '__main__':
    sys.exit(main())
