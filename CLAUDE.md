# Lua-Modules

## Running repository commands

The toolchain lives in the devcontainer, not on the host: Lua 5.1, busted,
luacheck, lua-language-server, ruff, and the Playwright browsers the visual
snapshot tests need. Run repository commands there so results match CI.

When the shell is already inside the container, which you can tell from the
workspace being under `/workspaces/`, run commands directly:

```
npm run lua-test
```

From the host, go through the devcontainer CLI, starting the container first if
it is not already up:

```
npx --yes @devcontainers/cli up --workspace-folder .
npx --yes @devcontainers/cli exec --workspace-folder . npm run lua-test
```

This needs Docker running. If Docker is not available, say so rather than
falling back to whatever is installed on the host — a host may have a different
Lua version, or no busted at all, and a result from it does not tell you what CI
will do.

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
