# Lua-Modules

## Running repository commands

The toolchain can be installed natively or come from the devcontainer, and both
are supported — see Setup in the README. Use whichever the machine already has
rather than assuming one; a native setup is common on Linux, while the
devcontainer saves a fight with Lua 5.1 on macOS.

Check before running rather than guessing: `command -v busted luacheck ruff`,
and `lua -v`, which needs to report 5.1. Anything newer is unsupported here, so
its results do not mean much.

With a native toolchain, or from a shell already inside the devcontainer, which
you can tell from the workspace being under `/workspaces/`, run commands
directly:

```
npm run lua-test
```

From the host with only the devcontainer set up, go through its CLI, starting
the container first if it is not already up:

```
npx --yes @devcontainers/cli up --workspace-folder .
npx --yes @devcontainers/cli exec --workspace-folder . npm run lua-test
```

If neither is available, say so instead of skipping a check or calling it
passed. Installing the Lua tools natively is `luarocks install --lua-version=5.1
busted`, and the same for `luacheck`; the devcontainer route needs Docker
running.

Say which of the two produced a result when it is not obvious. A native setup
can differ from CI in Lua patch version or ruff version, and whoever reads the
result should know which they got.

## Commands

- `npm run lua-test` — busted suite, builds the CSS first
- `luacheck lua --config lua/.luacheckrc` — Lua lint
- `npm run lint:scss` — SCSS lint
- `npm run lint:js` — JS lint, note that it runs `eslint --fix` and edits files
- `ruff check scripts/` and `ruff format --check scripts/` — Python
- `npm run build` — CSS and JS bundles

## Visual snapshots

Do not update snapshots locally. CI regenerates them and commits them back to
the branch, and reviewing that diff is part of reviewing the pull request.
Rendering is not identical across CPU architectures, so a local update can
produce changed files that are not real changes.

## Deploying to the wiki

`scripts/deploy.py` writes to liquipedia.net. Set `LUA_DEV_ENV_NAME` so it
targets sandbox pages, and keep `DRY_RUN=1` unless the intent is a live write.
With neither set, running it with no arguments resyncs every module to the live
wiki.
