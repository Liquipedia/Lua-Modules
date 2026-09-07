"""Run the busted suite under luacov and report coverage of lua/wikis/commons.

Coverage instrumentation is a per-line debug hook, so the suite takes roughly
20x longer than normal -- expect a couple of minutes rather than a second.

Needs busted and luacov on PATH, both for Lua 5.1:

    luarocks install --lua-version=5.1 busted
    luarocks install --lua-version=5.1 luacov

Scope and exclusions come from lua/.luacov. Modules no spec ever loads count as
0% rather than being left out, so the figure covers all of commons rather than
only the files the suite happens to touch.

Usage:
    python scripts/metrics/coverage.py [--skip-run]
"""

import argparse
import pathlib
import re
import subprocess
import sys

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
LUA_DIR = REPO_ROOT / "lua"
REPORT = LUA_DIR / "luacov.report.out"

TOTAL = re.compile(r"^Total\s+(\d+)\s+(\d+)\s+([\d.]+)%")
FILE_ROW = re.compile(r"^wikis/commons/\S+\s+\d+\s+\d+\s+([\d.]+)%$")


INSTALL_HINT = (
    "not found on PATH. Install both for Lua 5.1:\n"
    "  luarocks install --lua-version=5.1 busted\n"
    "  luarocks install --lua-version=5.1 luacov"
)


def run(command, cwd):
    try:
        subprocess.run(command, cwd=cwd, check=True)
    except FileNotFoundError:
        raise SystemExit(f"{command[0]} {INSTALL_HINT}") from None
    except subprocess.CalledProcessError as error:
        raise SystemExit(f"{command[0]} failed (exit {error.returncode})") from None


def run_suite():
    """Run the test suite under coverage, then render the luacov report."""
    run(["busted", "-C", "lua", "--run=ci", "-c"], REPO_ROOT)
    run(["luacov"], LUA_DIR)


def parse(report):
    lines = report.read_text(encoding="utf-8", errors="replace").split("\n")
    total = next((TOTAL.match(line) for line in lines if TOTAL.match(line)), None)
    if total is None:
        raise SystemExit(f"no Total line in {report}; did luacov run?")

    shares = [m.group(1) for m in map(FILE_ROW.match, lines) if m]
    return {
        "hits": int(total.group(1)),
        "missed": int(total.group(2)),
        "coverage_pct": float(total.group(3)),
        "files": len(shares),
        "uncovered": sum(1 for s in shares if float(s) == 0),
    }


def table(m):
    return [
        "| Coverage (lua/wikis/commons) | |",
        "|-|-|",
        f"| Coverage | {m['coverage_pct']:.2f}% |",
        f"| Lines hit | {m['hits']} |",
        f"| Lines missed | {m['missed']} |",
        f"| Files | {m['files']} |",
        f"| Files at 0% | {m['uncovered']} |",
    ]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--skip-run",
        action="store_true",
        help="reuse the existing luacov report instead of re-running the suite",
    )
    args = parser.parse_args()

    if not args.skip_run:
        run_suite()
    elif not REPORT.exists():
        print(f"::error::no report at {REPORT}; run without --skip-run first")
        return 1

    print("\n".join(table(parse(REPORT))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
