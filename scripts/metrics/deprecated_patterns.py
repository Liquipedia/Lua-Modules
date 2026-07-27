#!/usr/bin/env python3
"""Metric 3: deprecated / legacy pattern usage in repo-managed Lua code.

Counts call sites of patterns we want to see go to zero, across lua/wikis.
Each pattern is reported as a single total.

Only lua/wikis is scanned, so specs (lua/spec), type definitions
(lua/definitions) and vendored code (lua/3rd) are excluded by construction.
Comment-only lines are skipped.

To track a new pattern, add an entry to PATTERNS below. Its name becomes a new
column in --csv output; keep existing names stable so the time series stays
comparable.

Usage:
    python3 scripts/metrics/deprecated_patterns.py [--csv] [--files]

Intended to be run on a schedule (e.g. weekly CI job) with --csv appended to a
time-series file, so standardization / Phoenix progress can be charted.
"""

import argparse
import csv
import re
import sys
from datetime import date
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
WIKIS_DIR = REPO_ROOT / 'lua' / 'wikis'

PATTERNS: dict[str, dict] = {
    'widget2': {
        'description': 'class-based Widget2 implementations',
        # Class.new(Widget) and Class.new(Widget, function(self, props) ...
        # \b keeps this from matching e.g. Class.new(WidgetContext). Widgets
        # subclassing another widget are not counted -- the base class name is
        # not knowable without resolving imports, and direct extension is the
        # stable, cheap proxy.
        'regexes': [r'Class\.new\(\s*Widget\b'],
    },
    'scribunto_html': {
        'description': 'Scribunto mw.html node creations',
        # A root node, a new child node, and an existing node inserted into a
        # parent. :tag( and :node( are assumed to always be mw.html calls;
        # nothing else in the codebase uses those method names.
        'regexes': [r'mw\.html\.create\(', r':tag\(', r':node\('],
    },
}

COMPILED = {
    name: [re.compile(regex) for regex in spec['regexes']]
    for name, spec in PATTERNS.items()
}


def count_file(path: Path) -> dict[str, int]:
    """Return per-pattern call-site counts for a Lua file."""
    lines = [
        line for line in path.read_text(encoding='utf-8', errors='replace').splitlines()
        if not line.strip().startswith('--')
    ]
    return {
        name: sum(len(regex.findall(line)) for regex in regexes for line in lines)
        for name, regexes in COMPILED.items()
    }


def collect() -> tuple[dict[str, int], dict[str, list[tuple[Path, int]]]]:
    """Return (per-pattern totals, per-pattern list of (file, count) hits)."""
    totals = dict.fromkeys(PATTERNS, 0)
    hits: dict[str, list[tuple[Path, int]]] = {name: [] for name in PATTERNS}
    for lua_file in sorted(WIKIS_DIR.rglob('*.lua')):
        for name, count in count_file(lua_file).items():
            if count:
                totals[name] += count
                hits[name].append((lua_file.relative_to(REPO_ROOT), count))
    return totals, hits


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--csv', action='store_true', help='CSV output (for appending to a time series)')
    parser.add_argument('--files', action='store_true', help='list the files containing each pattern')
    args = parser.parse_args()

    totals, hits = collect()

    if args.csv:
        writer = csv.DictWriter(sys.stdout, fieldnames=['date', *PATTERNS])
        writer.writeheader()
        writer.writerow({'date': date.today().isoformat(), **totals})
        return

    width = max(len(name) for name in PATTERNS)
    for name, spec in PATTERNS.items():
        if args.files:
            print(f"{name} -- {spec['description']}")
            for path, count in hits[name]:
                print(f"    {count:>4}  {path}")
            print()
        else:
            print(f"{name:<{width}}  {totals[name]:>6}")
    if args.files:
        print('-' * 60)
        for name in PATTERNS:
            print(f"{name:<{width}}  {totals[name]:>6}")


if __name__ == '__main__':
    main()
