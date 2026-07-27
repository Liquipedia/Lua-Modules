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

Prints `key=value` lines so a caller can diff two runs and report the change.

Usage:
    python scripts/customization_metrics.py [wikis-root]
"""

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
    declarative = legacy = override = 0

    for path in sorted(pathlib.Path(root).rglob("*.lua")):
        posix = path.as_posix()
        # commons is the shared implementation, not per-wiki customization.
        if f"/{COMMONS}/" in posix or posix.endswith(f"/{COMMONS}"):
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        count = len(text.splitlines())

        if "Legacy" in posix:
            legacy += count
        elif is_override_code(text.splitlines()):
            override += count
        else:
            declarative += count

    total = override + declarative + legacy

    def share(count):
        return round(count / total * 100, 2) if total else 0.0

    return {
        "override_code": override,
        "declarative": declarative,
        "legacy": legacy,
        "total": total,
        "override_code_pct": share(override),
        "declarative_pct": share(declarative),
        "legacy_pct": share(legacy),
    }


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_ROOT
    if not pathlib.Path(root).is_dir():
        print(f"::error::wikis root not found: {root}")
        return 1
    for key, value in measure(root).items():
        print(f"{key}={value}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
