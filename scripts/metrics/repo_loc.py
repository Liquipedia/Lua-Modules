#!/usr/bin/env python3
"""Metric 1: repo Lua LOC per wiki.

Counts lines of repo-managed Lua code per wiki directory (lua/wikis/<wiki>),
with commons listed separately. LOC = non-blank, non-comment-only lines;
total physical lines and file counts are also reported.

Usage:
    python3 scripts/metrics/repo_loc.py [--csv] [--no-header]

Intended to be run on a schedule (e.g. weekly CI job) with --csv appended to a
time-series file, so standardization / Phoenix progress can be charted.
"""

import argparse
import csv
import sys
from datetime import date
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
WIKIS_DIR = REPO_ROOT / "lua" / "wikis"


def count_file(path: Path) -> tuple[int, int]:
    """Return (physical_lines, loc) for a Lua file."""
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    loc = sum(1 for line in lines if line.strip() and not line.strip().startswith("--"))
    return len(lines), loc


def collect() -> list[dict]:
    rows = []
    for wiki_dir in sorted(WIKIS_DIR.iterdir()):
        if not wiki_dir.is_dir():
            continue
        files = list(wiki_dir.rglob("*.lua"))
        total_lines = 0
        total_loc = 0
        for f in files:
            physical, loc = count_file(f)
            total_lines += physical
            total_loc += loc
        rows.append(
            {
                "date": date.today().isoformat(),
                "wiki": wiki_dir.name,
                "files": len(files),
                "lines": total_lines,
                "loc": total_loc,
            }
        )
    return rows


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--csv", action="store_true", help="CSV output (for appending to a time series)"
    )
    parser.add_argument(
        "--header",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="write the CSV header row (--no-header when appending "
        "to an existing time-series file)",
    )
    args = parser.parse_args()

    rows = collect()
    if args.csv:
        writer = csv.DictWriter(
            sys.stdout, fieldnames=["date", "wiki", "files", "lines", "loc"]
        )
        if args.header:
            writer.writeheader()
        writer.writerows(rows)
    else:
        print(f"{'wiki':<20} {'files':>6} {'lines':>9} {'loc':>9}")
        for row in rows:
            print(
                f"{row['wiki']:<20} {row['files']:>6} {row['lines']:>9} {row['loc']:>9}"
            )
        total_files = sum(r["files"] for r in rows)
        total_lines = sum(r["lines"] for r in rows)
        total_loc = sum(r["loc"] for r in rows)
        print("-" * 46)
        print(f"{'TOTAL':<20} {total_files:>6} {total_lines:>9} {total_loc:>9}")


if __name__ == "__main__":
    main()
