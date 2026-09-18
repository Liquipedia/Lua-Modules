# Metrics

Scripts that measure the codebase. Run them by hand whenever you want a number.

Each one prints a table. Add `--csv` to get rows you can append to a file instead.

## What's here

| Script | What it tells you |
|-|-|
| `repo_loc.py` | Lua LOC per wiki, in this repo |
| `onwiki_loc.py` | Lua LOC that lives on-wiki and isn't in this repo |
| `deprecated_patterns.py` | Call sites still using legacy patterns |
| `coverage.py` | Test coverage of `lua/wikis/commons` |
| `annotation_coverage.py` | How much of commons has `@param` / `@return` |
| `customization_metrics.py` | How much per-wiki override code there is |

## Running them

Most need nothing but Python:

```bash
python3 scripts/metrics/repo_loc.py
```

`coverage.py` runs the test suite, so it needs busted and luacov on Lua 5.1:

```bash
luarocks install --lua-version=5.1 busted
luarocks install --lua-version=5.1 luacov
python3 scripts/metrics/coverage.py
```

`onwiki_loc.py` calls the live wiki API:

```bash
pip install -r requirements.txt
WIKI_BASE_URL=https://liquipedia.net python3 scripts/metrics/onwiki_loc.py
```

## Tracking over time

```bash
python3 scripts/metrics/repo_loc.py --csv --no-header >> metrics.csv
```

Run any script with `--help` for the rest of its options.
