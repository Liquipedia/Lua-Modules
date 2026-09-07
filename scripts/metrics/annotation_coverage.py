#!/usr/bin/env python3
"""Metric 5: LuaLS annotation coverage of exported functions in commons.

Annotations are what make commons modules statically understandable, so this
tracks how much of the exported surface carries them.

A function counts as annotated when the contiguous comment block directly above
it mentions `@param` or `@return`. Only `function M.name(...)` and
`function M:name(...)` forms are counted -- that is the shape the doc-block
convention applies to in this codebase.

A function taking no parameters and returning no value needs neither tag, so it
is reported as exempt and left out of the ratio rather than counted against it.
Whether a body returns a value is decided by scanning to the `end` at the
function's own indentation, which is a heuristic: when in doubt it assumes a
value is returned, so a function is more likely to be asked for an annotation
than excused from one.

Usage:
    python3 scripts/metrics/annotation_coverage.py [--csv] [--no-header]
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
DEFAULT_ROOT = REPO_ROOT / "lua" / "wikis" / "commons"

FUNCTION = re.compile(r"^(\s*)function\s+[A-Za-z_][\w.]*[.:]\w+\s*\(([^)]*)\)")
RETURNS_VALUE = re.compile(r"\breturn\s+\S")

FIELDS = [
    "functions",
    "annotated",
    "exempt",
    "needs_annotation",
    "unannotated",
    "coverage_pct",
    "params_total",
    "params_annotated",
    "params_pct",
]


def doc_block(lines: list[str], index: int) -> str:
    """Return the contiguous comment block immediately above lines[index]."""
    block = []
    cursor = index - 1
    while cursor >= 0 and lines[cursor].lstrip().startswith("--"):
        block.append(lines[cursor])
        cursor -= 1
    return "\n".join(block)


def returns_value(lines: list[str], index: int, indent: str) -> bool:
    """Whether the function starting at lines[index] returns a value."""
    end = re.compile(rf"^{indent}end\b")
    for line in lines[index + 1 :]:
        if end.match(line):
            return False
        if RETURNS_VALUE.search(line):
            return True
    return True  # no clear end found: assume it returns, so we still ask for a tag


def collect(root: Path) -> dict:
    functions = annotated = exempt = params_total = params_annotated = 0

    for path in sorted(root.rglob("*.lua")):
        # ScribuntoUnit testcases run on-wiki and are not part of the surface.
        if "test" in path.parts:
            continue
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        for index, line in enumerate(lines):
            match = FUNCTION.match(line)
            if not match:
                continue
            indent, raw = match.group(1), match.group(2)
            params = [p.strip() for p in raw.split(",") if p.strip()]
            params = [p for p in params if p != "self"]
            block = doc_block(lines, index)

            functions += 1
            if "@param" in block or "@return" in block:
                annotated += 1
            elif not params and not returns_value(lines, index, indent):
                exempt += 1
            if params:
                params_total += 1
                if block.count("@param") >= len(params):
                    params_annotated += 1

    needs = functions - exempt
    return {
        "functions": functions,
        "annotated": annotated,
        "exempt": exempt,
        "needs_annotation": needs,
        "unannotated": needs - annotated,
        "coverage_pct": round(annotated / needs * 100, 2) if needs else 0.0,
        "params_total": params_total,
        "params_annotated": params_annotated,
        "params_pct": (
            round(params_annotated / params_total * 100, 2) if params_total else 0.0
        ),
    }


def print_table(head: dict, base: Optional[dict]) -> None:
    for field in FIELDS:
        value = head[field]
        cell = f"{value:.2f}%" if field.endswith("_pct") else str(value)
        if base is not None:
            delta = value - base[field]
            cell += (
                f" ({delta:+.2f} pp)" if field.endswith("_pct") else f" ({delta:+d})"
            )
        print(f"{field.replace('_', ' '):<20}{cell:>22}")


def print_csv(head: dict, header: bool) -> None:
    writer = csv.writer(sys.stdout)
    if header:
        writer.writerow(["date"] + FIELDS)
    writer.writerow([date.today().isoformat()] + [head[f] for f in FIELDS])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", type=Path, default=DEFAULT_ROOT)
    parser.add_argument("--csv", action="store_true", help="CSV for appending")
    parser.add_argument("--no-header", action="store_true", help="omit the CSV header")
    parser.add_argument(
        "--base", type=Path, help="compare against this tree (table mode only)"
    )
    args = parser.parse_args()

    if not args.root.is_dir():
        print(f"annotation root not found: {args.root}", file=sys.stderr)
        return 1

    head = collect(args.root)
    if args.csv:
        print_csv(head, header=not args.no_header)
        return 0

    base = None
    if args.base:
        if args.base.is_dir():
            base = collect(args.base)
        else:
            print(f"base root not found, omitting deltas: {args.base}", file=sys.stderr)
    print_table(head, base)
    return 0


if __name__ == "__main__":
    sys.exit(main())
