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
"""

from __future__ import annotations

import argparse
import pathlib
import re
import sys

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


class Module:
    """A lua module, classified by where it sits in the layering."""

    def __init__(self, path: pathlib.Path):
        self.path = path
        parts = path.relative_to(LUA_ROOT).with_suffix("").parts
        self.name = "/".join(parts[1:])
        self.wiki = parts[0]
        self.layer, self.feature, self.tier, self.group = classify("/".join(parts[1:]))

    def imports(self) -> list[str]:
        return IMPORT_RE.findall(self.path.read_text(encoding="utf-8"))


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


def violations(module: Module) -> list[str]:
    found = []
    for name in module.imports():
        layer, feature, tier, group = classify(name)

        if layer == "feature" and feature != module.feature and tier != ENTRY_TIER:
            found.append(f"reaches into {feature}'s internals: Module:{name}")

        if (
            layer == "feature"
            and feature != module.feature
            and module.layer == "feature"
        ):
            found.append(f"imports another feature: Module:{name}")

        if layer == "feature" and module.layer == "domain":
            found.append(f"domain must not import a feature: Module:{name}")

        if module.layer == "domain":
            reason = DOMAIN_FORBIDDEN_ROOTS.get(name.split("/")[0])
            for pattern, why in DOMAIN_FORBIDDEN_PATTERNS.items():
                if pattern in name:
                    reason = why
            if reason:
                found.append(f"domain {reason}: Module:{name}")

        if (
            layer == "feature"
            and feature == module.feature
            and None not in (tier, module.tier)
        ):
            # Peers inside one tier folder may compose each other; crossing between them may not.
            if tier > module.tier:
                found.append(f"imports upward within {feature}: Module:{name}")
            elif tier == module.tier and group != module.group:
                found.append(f"imports sideways within {feature}: Module:{name}")

    return found


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.parse_args()

    errors, warnings = [], []
    for path in sorted(LUA_ROOT.rglob("*.lua")):
        module = Module(path)
        # A violation coming out of restructured code breaks work already done, so it fails.
        bucket = warnings if module.layer == "unclassified" else errors
        for message in violations(module):
            bucket.append(f"{path}: {message}")

    for message in errors:
        print(f"error: {message}")
    for message in warnings:
        print(f"warning: {message}")

    if not errors and not warnings:
        print("No import rule violations.")
    else:
        print(f"\n{len(errors)} error(s), {len(warnings)} warning(s).")

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
