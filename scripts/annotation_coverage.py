"""Measure LuaLS annotation coverage of exported functions in lua/wikis/commons.

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

Prints a Markdown table, optionally with deltas against a second tree. Pass
--raw for `key=value` output instead.

Usage:
    python scripts/annotation_coverage.py [root] [--base BASE_ROOT] [--raw]
"""

import argparse
import pathlib
import re
import sys

FUNCTION = re.compile(r"^(\s*)function\s+[A-Za-z_][\w.]*[.:]\w+\s*\(([^)]*)\)")
RETURNS_VALUE = re.compile(r"\breturn\s+\S")
DEFAULT_ROOT = "lua/wikis/commons"


def doc_block(lines, index):
    """Return the contiguous comment block immediately above lines[index]."""
    block = []
    cursor = index - 1
    while cursor >= 0 and lines[cursor].lstrip().startswith("--"):
        block.append(lines[cursor])
        cursor -= 1
    return "\n".join(block)


def returns_value(lines, index, indent):
    """Whether the function starting at lines[index] returns a value."""
    end = re.compile(rf"^{indent}end\b")
    for line in lines[index + 1 :]:
        if end.match(line):
            return False
        if RETURNS_VALUE.search(line):
            return True
    return True  # no clear end found: assume it returns, so we still ask for a tag


def measure(root):
    functions = annotated = exempt = params_total = params_annotated = 0

    for path in sorted(pathlib.Path(root).rglob("*.lua")):
        # ScribuntoUnit testcases run on-wiki and are not part of the surface.
        if "test" in path.parts:
            continue
        lines = path.read_text(encoding="utf-8", errors="replace").split("\n")
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


def count_cell(value, base):
    return f"{value}" if base is None else f"{value} ({value - base:+d})"


def pct_cell(value, base):
    if base is None:
        return f"{value:.2f}%"
    return f"{value:.2f}% ({value - base:+.2f} pp)"


def table(head, base):
    def of(key):
        return None if base is None else base[key]

    rows = [
        (
            "Exported functions annotated",
            pct_cell(head["coverage_pct"], of("coverage_pct")),
        ),
        (
            "Needs annotation",
            count_cell(head["needs_annotation"], of("needs_annotation")),
        ),
        ("Unannotated", count_cell(head["unannotated"], of("unannotated"))),
        ("Exempt (no params, no return)", count_cell(head["exempt"], of("exempt"))),
        ("Exported functions", count_cell(head["functions"], of("functions"))),
        (
            "Functions with all params annotated",
            pct_cell(head["params_pct"], of("params_pct")),
        ),
    ]
    lines = ["| Annotations (lua/wikis/commons) | |", "|-|-|"]
    lines += [f"| {label} | {value} |" for label, value in rows]
    if base is None:
        lines.append("| | _no baseline available; deltas omitted_ |")
    return lines


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", default=DEFAULT_ROOT)
    parser.add_argument("--base", help="second tree to compare against")
    parser.add_argument("--raw", action="store_true", help="print key=value instead")
    args = parser.parse_args()

    if not pathlib.Path(args.root).is_dir():
        print(f"::error::annotation root not found: {args.root}")
        return 1

    head = measure(args.root)
    if args.raw:
        for key, value in head.items():
            print(f"{key}={value}")
        return 0

    base = None
    if args.base:
        if pathlib.Path(args.base).is_dir():
            base = measure(args.base)
        else:
            print(f"::warning::base root not found, omitting deltas: {args.base}")
    print("\n".join(table(head, base)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
