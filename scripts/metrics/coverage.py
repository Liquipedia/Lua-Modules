#!/usr/bin/env python3
"""Metric 6: busted test coverage of lua/wikis/commons.

Runs the test suite under luacov and reports how much of commons it exercises.
Coverage instrumentation is a per-line debug hook, so the suite takes roughly
20x longer than normal -- expect about half a minute rather than a second.

Needs busted and luacov on PATH, both for Lua 5.1:

    luarocks install --lua-version=5.1 busted
    luarocks install --lua-version=5.1 luacov

Scope and exclusions come from lua/.luacov. Modules no spec ever loads count as
0% rather than being left out, so the figure covers all of commons rather than
only the files the suite happens to touch.

Usage:
    python3 scripts/metrics/coverage.py [--csv] [--no-header] [--skip-run]

Intended to be run on a schedule (e.g. weekly CI job) with --csv appended to a
time-series file, so standardization / Phoenix progress can be charted.
"""

import argparse
import csv
import re
import subprocess
import sys
from datetime import date
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
LUA_DIR = REPO_ROOT / "lua"
REPORT = LUA_DIR / "luacov.report.out"
STATS = LUA_DIR / "luacov.stats.out"

TOTAL = re.compile(r"^Total\s+(\d+)\s+(\d+)\s+([\d.]+)%")
FILE_ROW = re.compile(r"^wikis/commons/\S+\s+\d+\s+\d+\s+([\d.]+)%$")

FIELDS = ["coverage_pct", "hits", "missed", "files", "files_at_zero"]

INSTALL_HINT = (
    "not found on PATH. Install both for Lua 5.1:\n"
    "  luarocks install --lua-version=5.1 busted\n"
    "  luarocks install --lua-version=5.1 luacov"
)


def run(command: list[str], cwd: Path) -> None:
    try:
        subprocess.run(command, cwd=cwd, check=True)
    except FileNotFoundError:
        raise SystemExit(f"{command[0]} {INSTALL_HINT}") from None
    except subprocess.CalledProcessError as error:
        raise SystemExit(f"{command[0]} failed (exit {error.returncode})") from None


def run_suite() -> None:
    """Run the test suite under coverage, then render the luacov report."""
    # lua/.luacov keeps stats so a report can be regenerated, which means a
    # stale file would be reused and report the previous run's coverage.
    STATS.unlink(missing_ok=True)
    REPORT.unlink(missing_ok=True)
    run(["busted", "-C", "lua", "--run=ci", "-c"], REPO_ROOT)
    run(["luacov"], LUA_DIR)


def collect(report: Path) -> dict:
    if not report.exists():
        raise SystemExit(f"no report at {report}; luacov produced nothing")
    lines = report.read_text(encoding="utf-8", errors="replace").splitlines()
    total = next((TOTAL.match(line) for line in lines if TOTAL.match(line)), None)
    if total is None:
        raise SystemExit(f"no Total line in {report}; did luacov run?")

    shares = [m.group(1) for m in map(FILE_ROW.match, lines) if m]
    return {
        "coverage_pct": float(total.group(3)),
        "hits": int(total.group(1)),
        "missed": int(total.group(2)),
        "files": len(shares),
        "files_at_zero": sum(1 for s in shares if float(s) == 0),
    }


def print_table(metrics: dict) -> None:
    for field in FIELDS:
        value = metrics[field]
        cell = f"{value:.2f}%" if field.endswith("_pct") else str(value)
        print(f"{field.replace('_', ' '):<16}{cell:>12}")


def print_csv(metrics: dict, header: bool) -> None:
    writer = csv.writer(sys.stdout)
    if header:
        writer.writerow(["date"] + FIELDS)
    writer.writerow([date.today().isoformat()] + [metrics[f] for f in FIELDS])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--csv", action="store_true", help="CSV for appending")
    parser.add_argument("--no-header", action="store_true", help="omit the CSV header")
    parser.add_argument(
        "--skip-run",
        action="store_true",
        help="reuse the existing luacov report instead of re-running the suite",
    )
    args = parser.parse_args()

    if not args.skip_run:
        run_suite()
    elif not REPORT.exists():
        print(f"no report at {REPORT}; run without --skip-run first", file=sys.stderr)
        return 1

    metrics = collect(REPORT)
    if args.csv:
        print_csv(metrics, header=not args.no_header)
    else:
        print_table(metrics)
    return 0


if __name__ == "__main__":
    sys.exit(main())
