"""Check the layering rules from the bulletproof-lua RFC.

Three layers, and imports only point down: features -> domain -> shared. Within a feature they
point down too: an entry point may reach the controller, the controller may reach
Components/Api/Lib, and those may reach Types.

Only the parts of the tree that have been moved onto the structure are classified. Everything
that has not been restructured yet is "unclassified", and is only used to detect reaching into a
feature's internals from outside; it is not itself held to the layer rules.

Enforcement is graduated. Code that has been moved onto the structure is held to the rules and
fails the build, because a regression there is a regression in work already done. Unclassified code
only warns, because it has not been migrated yet; those warnings become errors as each area moves.

On GitHub Actions each violation is printed as a workflow command so it lands on the diff of the
offending line. Run anywhere else it is plain text on stderr instead.
"""

from __future__ import annotations

import argparse
import os
import pathlib
import re
import sys
from typing import NamedTuple

LUA_ROOT = pathlib.Path("lua/wikis")
IMPORT_RE = re.compile(
    r"""(?:Lua\.import|Lua\.requireIfExists|require)\(\s*['"]Module:([^'"]+)['"]"""
)

# Feature tiers, lowest first. Modules directly in the feature folder are entry points.
TIERS = {"Types": 0, "Lib": 1, "Api": 1, "Components": 1, "Controller": 2}
ENTRY_TIER = 3

# Domain holds the site's entities and their rules. It may read per wiki *config* (Info.config is
# data, and every rule read from it must be overridable by a parameter so the entity stays
# testable), but it may not render, and it may not reach for per wiki *code*: that is a feature
# concern and it cannot be substituted in a test.
DOMAIN_FORBIDDEN_ROOTS = {"Widget": "renders"}
DOMAIN_FORBIDDEN_PATTERNS = {
    "Brkts/WikiSpecific": "reaches for per wiki code",
    "/Custom": "reaches for per wiki code",
}


class Violation(NamedTuple):
    """One broken rule, located at the import that broke it."""

    path: pathlib.Path
    line: int
    column: int
    message: str


class Module:
    """A lua module, classified by where it sits in the layering."""

    def __init__(self, path: pathlib.Path):
        self.path = path
        parts = path.relative_to(LUA_ROOT).with_suffix("").parts
        self.name = "/".join(parts[1:])
        self.wiki = parts[0]
        self.layer, self.feature, self.tier, self.group = classify("/".join(parts[1:]))

    def imports(self) -> list[tuple[str, int, int]]:
        """Every imported module name, with the line and column it is imported on."""
        text = self.path.read_text(encoding="utf-8")
        found = []
        for match in IMPORT_RE.finditer(text):
            line = text.count("\n", 0, match.start()) + 1
            column = match.start() - text.rfind("\n", 0, match.start())
            found.append((match.group(1), line, column))
        return found


def classify(name: str) -> tuple[str, str | None, int | None, str | None]:
    """Classify a module name into layer, feature, tier and tier folder."""
    parts = name.split("/")
    if parts[0] == "Features" and len(parts) > 1:
        rest = parts[2:]
        # Types.lua and Controller.lua are tiers that sit directly in the feature folder;
        # anything else there (Custom.lua, Auto.lua) is an entry point.
        group = rest[0] if rest and rest[0] in TIERS else None
        tier = TIERS[group] if group else ENTRY_TIER
        return "feature", parts[1], tier, group
    if parts[0] == "Domain":
        return "domain", None, None, None
    return "unclassified", None, None, None


def violations(module: Module) -> list[Violation]:
    found = []
    for name, line, column in module.imports():
        layer, feature, tier, group = classify(name)

        def report(message: str) -> None:
            found.append(Violation(module.path, line, column, message))

        if layer == "feature" and feature != module.feature and tier != ENTRY_TIER:
            report(f"reaches into {feature}'s internals: Module:{name}")

        if (
            layer == "feature"
            and feature != module.feature
            and module.layer == "feature"
        ):
            report(f"imports another feature: Module:{name}")

        if layer == "feature" and module.layer == "domain":
            report(f"domain must not import a feature: Module:{name}")

        if module.layer == "domain":
            reason = DOMAIN_FORBIDDEN_ROOTS.get(name.split("/")[0])
            for pattern, why in DOMAIN_FORBIDDEN_PATTERNS.items():
                if pattern in name:
                    reason = why
            if reason:
                report(f"domain {reason}: Module:{name}")

        if (
            layer == "feature"
            and feature == module.feature
            and None not in (tier, module.tier)
        ):
            # Peers inside one tier folder may compose each other; crossing between them may not.
            if tier > module.tier:
                report(f"imports upward within {feature}: Module:{name}")
            elif tier == module.tier and group != module.group:
                report(f"imports sideways within {feature}: Module:{name}")

    return found


def report_github(level: str, violation: Violation) -> None:
    """Print a workflow command, so the violation is annotated on the line that caused it."""
    # Workflow commands are read off stdout, and the data in them has to be escaped.
    message = violation.message
    for char, replacement in (("%", "%25"), ("\r", "%0D"), ("\n", "%0A")):
        message = message.replace(char, replacement)
    print(
        f"::{level} file={violation.path},"
        f"line={violation.line},col={violation.column}::{message}"
    )


def report_plain(level: str, violation: Violation) -> None:
    print(
        f"{level}: {violation.path}:{violation.line}: {violation.message}",
        file=sys.stderr,
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.parse_args()

    errors: list[Violation] = []
    warnings: list[Violation] = []
    for path in sorted(LUA_ROOT.rglob("*.lua")):
        module = Module(path)
        # A violation coming out of restructured code breaks work already done, so it fails.
        bucket = warnings if module.layer == "unclassified" else errors
        bucket.extend(violations(module))

    report = (
        report_github if os.environ.get("GITHUB_ACTIONS") == "true" else report_plain
    )
    for level, found in (("error", errors), ("warning", warnings)):
        for violation in found:
            report(level, violation)

    if not errors and not warnings:
        print("No import rule violations.")
    else:
        print(f"\n{len(errors)} error(s), {len(warnings)} warning(s).")

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
