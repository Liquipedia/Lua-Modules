"""Measure how much per-wiki customization code lives outside lua/wikis/commons.

Everything in this repo is standardized; what varies is how much a wiki has to
override to get the behaviour it wants. Override code is the part that costs
maintenance and has to be carried forward, so it is the number worth watching.
Declarative data and config, and legacy shims, are reported separately.

Classification is by file *content*, not filename -- `GetMatchGroupCopyPaste/
wiki.lua`, `FilterButtons/Config.lua` and `NotabilityChecker/config.lua` all
look declarative and are not. A file is override code when it defines a
non-local function, or when a `local function` is exported via a `return`
statement (the widget pattern: `local function X` ... `return wrap(X)`).
Purely-local helpers inside an otherwise declarative file do not promote it.

Shares are against the whole of lua/wikis (commons included), so "override code
is 37% of all Lua" is answerable. Vendored code, type stubs, specs and test
assets under lua/ are excluded from the denominator -- they are not the product.

Prints a Markdown table, optionally with deltas against a second tree. Pass
--raw for `key=value` output instead.

Usage:
    python scripts/customization_metrics.py [wikis-root] [--base BASE_ROOT] [--raw]
"""

import argparse
import pathlib
import re
import sys

DEFAULT_ROOT = "lua/wikis"
COMMONS = "commons"

EXPORTED_FUNCTION = re.compile(r"\bfunction\b")
LOCAL_FUNCTION = re.compile(
    r"^[ \t]*local[ \t]+(?:function|[A-Za-z_][A-Za-z0-9_]*[ \t]*=[ \t]*function)"
)
LOCAL_FUNCTION_NAME = re.compile(r"^[ \t]*local[ \t]+function[ \t]+([A-Za-z_]\w*)")
RETURN_STATEMENT = re.compile(r"^[ \t]*return\b")


def is_override_code(lines):
    """True when the file exposes behaviour rather than just data or config."""
    local_names = []
    returns = []
    for line in lines:
        if not EXPORTED_FUNCTION.search(line):
            if RETURN_STATEMENT.match(line):
                returns.append(line)
            continue
        if not LOCAL_FUNCTION.match(line):
            return True  # a non-local function definition
        name = LOCAL_FUNCTION_NAME.match(line)
        if name:
            local_names.append(name.group(1))

    # A local function handed out through `return` is the module's interface.
    return any(name in line for line in returns for name in local_names)


def measure(root):
    declarative = legacy = override = commons = 0

    for path in sorted(root.rglob("*.lua")):
        text = path.read_text(encoding="utf-8", errors="replace")
        count = len(text.splitlines())

        # commons is the shared implementation, not per-wiki customization. It is
        # still counted, so shares have the whole of lua/wikis as denominator.
        if COMMONS in path.parts:
            commons += count
        # Substring, not a path component: legacy lives in directories
        # (TeamCard/Legacy/Custom.lua) *and* in filenames (Match/Legacy.lua).
        # `"Legacy" in path.parts` would miss the latter -- 52 of 78 files,
        # moving 6279 lines out of legacy and into override code.
        elif "Legacy" in path.as_posix():
            legacy += count
        elif is_override_code(text.splitlines()):
            override += count
        else:
            declarative += count

    per_wiki = override + declarative + legacy
    total = per_wiki + commons

    def share(count):
        return round(count / total * 100, 2) if total else 0.0

    return {
        "override_code": override,
        "declarative": declarative,
        "legacy": legacy,
        "per_wiki_total": per_wiki,
        "commons": commons,
        "total": total,
        "override_code_pct": share(override),
        "declarative_pct": share(declarative),
        "legacy_pct": share(legacy),
        "per_wiki_total_pct": share(per_wiki),
        "commons_pct": share(commons),
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
        ("**Override code**", "override_code", "override_code_pct"),
        ("Declarative (data + config)", "declarative", "declarative_pct"),
        ("Legacy", "legacy", "legacy_pct"),
        ("Per-wiki total", "per_wiki_total", "per_wiki_total_pct"),
        ("lua/wikis/commons (shared)", "commons", "commons_pct"),
    ]
    lines = [
        "| Per-wiki customization | LOC | Share of all Lua |",
        "|-|-|-|",
    ]
    for label, loc_key, pct_key in rows:
        loc = count_cell(head[loc_key], of(loc_key))
        pct = pct_cell(head[pct_key], of(pct_key))
        if label.startswith("**"):
            loc, pct = f"**{loc}**", f"**{pct}**"
        lines.append(f"| {label} | {loc} | {pct} |")
    lines.append(f"| All of lua/wikis | {count_cell(head['total'], of('total'))} | |")
    if base is None:
        lines.append("| | _no baseline available; deltas omitted_ | |")
    return lines


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", type=pathlib.Path, default=DEFAULT_ROOT)
    parser.add_argument(
        "--base", type=pathlib.Path, help="second tree to compare against"
    )
    parser.add_argument("--raw", action="store_true", help="print key=value instead")
    args = parser.parse_args()

    if not args.root.is_dir():
        print(f"::error::wikis root not found: {args.root}")
        return 1

    head = measure(args.root)
    if args.raw:
        for key, value in head.items():
            print(f"{key}={value}")
        return 0

    base = None
    if args.base:
        if args.base.is_dir():
            base = measure(args.base)
        else:
            print(f"::warning::base root not found, omitting deltas: {args.base}")
    print("\n".join(table(head, base)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
