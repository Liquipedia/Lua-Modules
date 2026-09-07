#!/usr/bin/env python3
"""Metric 4: per-wiki customization of repo-managed Lua code.

Everything in this repo is standardized; what varies is how much a wiki has to
override to get the behaviour it wants. Override code is the part that carries
maintenance cost, so it is the number worth watching. Declarative data/config
and legacy shims are counted separately -- a wiki adding 500 lines of faction
data is not the same event as one adding 500 lines of overrides.

Categories are decided by file *content*, not filename: `GetMatchGroupCopyPaste/
wiki.lua`, `FilterButtons/Config.lua` and `NotabilityChecker/config.lua` all
look declarative and are not. A file is override code when it defines a
non-local function, or exports a `local function` through a `return` statement
(the widget pattern: `local function X` ... `return wrap(X)`). Purely-local
helpers in an otherwise declarative file do not promote it. Any path containing
`Legacy` is counted as legacy before the content check.

commons is counted too, so shares have the whole of lua/wikis as denominator
and "override code is 37% of all Lua" is answerable. LOC matches metric 1:
non-blank, non-comment-only lines, with total physical lines also reported.

Usage:
    python3 scripts/metrics/customization_metrics.py [--csv] [--no-header]
                                                     [--base BASE_ROOT] [root]

Intended to be run on a schedule (e.g. weekly CI job) with --csv appended to a
time-series file, so standardization / Phoenix progress can be charted.
"""

import argparse
import csv
import re
import sys
from datetime import date
from pathlib import Path
from typing import Optional

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
DEFAULT_ROOT = REPO_ROOT / "lua" / "wikis"
COMMONS = "commons"

# A definition is the `function` keyword followed by an optional name and `(`.
# Matching the bare keyword would also catch prose in comments.
FUNCTION_DEF = re.compile(r"\bfunction\b\s*[A-Za-z_][\w.:]*\s*\(|\bfunction\b\s*\(")
# Both local forms, so a local exported via `return` is found either way.
LOCAL_DEF = re.compile(r"^[ \t]*local[ \t]+function[ \t]+([A-Za-z_]\w*)")
LOCAL_ASSIGN = re.compile(r"^[ \t]*local[ \t]+([A-Za-z_]\w*)[ \t]*=[ \t]*function\b")
RETURN_STATEMENT = re.compile(r"^[ \t]*return\b")
LINE_COMMENT = re.compile(r"--.*$")

# Order is the display order; per-wiki categories first, then commons.
CATEGORIES = ["override", "declarative", "legacy", "commons"]


def is_override_code(lines: list[str]) -> bool:
    """True when the file exposes behaviour rather than just data or config."""
    local_names = []
    returns = []
    for raw in lines:
        line = LINE_COMMENT.sub("", raw)
        if not FUNCTION_DEF.search(line):
            if RETURN_STATEMENT.match(line):
                returns.append(line)
            continue
        local = LOCAL_DEF.match(line) or LOCAL_ASSIGN.match(line)
        if not local:
            return True  # a non-local function definition
        local_names.append(local.group(1))

    # A local function handed out through `return` is the module's interface.
    # `name` not followed by `(` distinguishes handing it out (`return F`,
    # `return wrap(F)`) from calling it to build data (`return {a = h()}`),
    # which leaves the file declarative. Word-anchored so a short local name
    # cannot match an unrelated identifier.
    exported = [re.compile(rf"\b{re.escape(n)}\b\s*(?!\()") for n in local_names]
    return any(pattern.search(line) for line in returns for pattern in exported)


def categorise(path: Path, lines: list[str]) -> str:
    if COMMONS in path.parts:
        return "commons"
    # Substring, not a path component: legacy lives in directories
    # (TeamCard/Legacy/Custom.lua) *and* in filenames (Match/Legacy.lua).
    # `"Legacy" in path.parts` would miss the latter -- 52 of 78 files.
    if "Legacy" in path.as_posix():
        return "legacy"
    return "override" if is_override_code(lines) else "declarative"


def count_file(lines: list[str]) -> tuple[int, int]:
    """Return (physical_lines, loc) -- loc as metric 1 defines it."""
    loc = sum(1 for line in lines if line.strip() and not line.strip().startswith("--"))
    return len(lines), loc


def collect(root: Path) -> list[dict]:
    totals = {c: {"files": 0, "lines": 0, "loc": 0} for c in CATEGORIES}

    for path in sorted(root.rglob("*.lua")):
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        physical, loc = count_file(lines)
        bucket = totals[categorise(path, lines)]
        bucket["files"] += 1
        bucket["lines"] += physical
        bucket["loc"] += loc

    total_loc = sum(b["loc"] for b in totals.values())
    rows = []
    for category in CATEGORIES:
        bucket = totals[category]
        rows.append(
            {
                "category": category,
                "files": bucket["files"],
                "lines": bucket["lines"],
                "loc": bucket["loc"],
                "share": round(bucket["loc"] / total_loc * 100, 2)
                if total_loc
                else 0.0,
            }
        )
    return rows


def print_table(rows: list[dict], base: Optional[list[dict]]) -> None:
    by_category = {r["category"]: r for r in base} if base else {}
    print(f"{'category':<14}{'files':>7}{'lines':>10}{'loc':>10}{'share':>9}")
    for row in rows:
        share = f"{row['share']:.2f}%"
        if row["category"] in by_category:
            delta = row["loc"] - by_category[row["category"]]["loc"]
            share += f" ({delta:+d} loc)"
        print(
            f"{row['category']:<14}{row['files']:>7}{row['lines']:>10}"
            f"{row['loc']:>10}{share:>9}"
        )
    per_wiki = [r for r in rows if r["category"] != "commons"]
    per_wiki_loc = sum(r["loc"] for r in per_wiki)
    total_loc = sum(r["loc"] for r in rows)
    # From the loc totals, not by adding up the rounded per-category shares.
    share = per_wiki_loc / total_loc * 100 if total_loc else 0.0
    print(
        f"{'per-wiki total':<14}{sum(r['files'] for r in per_wiki):>7}"
        f"{sum(r['lines'] for r in per_wiki):>10}{per_wiki_loc:>10}"
        f"{share:>8.2f}%"
    )


def print_csv(rows: list[dict], header: bool) -> None:
    writer = csv.writer(sys.stdout)
    if header:
        writer.writerow(["date", "category", "files", "lines", "loc", "share"])
    today = date.today().isoformat()
    for row in rows:
        writer.writerow(
            [
                today,
                row["category"],
                row["files"],
                row["lines"],
                row["loc"],
                row["share"],
            ]
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", nargs="?", type=Path, default=DEFAULT_ROOT)
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
    parser.add_argument(
        "--base", type=Path, help="compare loc against this tree (table mode only)"
    )
    args = parser.parse_args()

    if not args.root.is_dir():
        print(f"wikis root not found: {args.root}", file=sys.stderr)
        return 1

    rows = collect(args.root)
    if args.csv:
        print_csv(rows, header=args.header)
        return 0

    base = None
    if args.base:
        if args.base.is_dir():
            base = collect(args.base)
        else:
            print(f"base root not found, omitting deltas: {args.base}", file=sys.stderr)
    print_table(rows, base)
    return 0


if __name__ == "__main__":
    sys.exit(main())
