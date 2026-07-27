"""Measure LuaLS annotation coverage of exported functions in lua/wikis/commons.

Annotations are what make commons modules statically understandable, so this
tracks how much of the exported surface carries them. Prints `key=value` lines
so a caller can diff two runs and report the change.

A function counts as annotated when the contiguous comment block directly above
it mentions `@param` or `@return`. Only `function M.name(...)` and
`function M:name(...)` forms are counted -- that is the shape the doc-block
convention applies to in this codebase.

Usage:
    python scripts/annotation_coverage.py [root]
"""

import pathlib
import re
import sys

FUNCTION = re.compile(r"^\s*function\s+[A-Za-z_][\w.]*[.:]\w+\s*\(([^)]*)\)")
DEFAULT_ROOT = "lua/wikis/commons"


def doc_block(lines, index):
    """Return the contiguous comment block immediately above lines[index]."""
    block = []
    cursor = index - 1
    while cursor >= 0 and lines[cursor].lstrip().startswith("--"):
        block.append(lines[cursor])
        cursor -= 1
    return "\n".join(block)


def measure(root):
    functions = annotated = params_total = params_annotated = 0

    for path in sorted(pathlib.Path(root).rglob("*.lua")):
        # ScribuntoUnit testcases run on-wiki and are not part of the surface.
        if "/test/" in path.as_posix():
            continue
        lines = path.read_text(encoding="utf-8", errors="replace").split("\n")
        for index, line in enumerate(lines):
            match = FUNCTION.match(line)
            if not match:
                continue
            params = [p.strip() for p in match.group(1).split(",") if p.strip()]
            params = [p for p in params if p != "self"]
            block = doc_block(lines, index)

            functions += 1
            if "@param" in block or "@return" in block:
                annotated += 1
            if params:
                params_total += 1
                if block.count("@param") >= len(params):
                    params_annotated += 1

    return {
        "functions": functions,
        "annotated": annotated,
        "unannotated": functions - annotated,
        "coverage_pct": round(annotated / functions * 100, 2) if functions else 0.0,
        "params_total": params_total,
        "params_annotated": params_annotated,
        "params_pct": (
            round(params_annotated / params_total * 100, 2) if params_total else 0.0
        ),
    }


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_ROOT
    if not pathlib.Path(root).is_dir():
        print(f"::error::annotation root not found: {root}")
        return 1
    for key, value in measure(root).items():
        print(f"{key}={value}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
