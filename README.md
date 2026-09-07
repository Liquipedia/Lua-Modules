# Lua-Modules

![Code Style](https://github.com/Liquipedia/LiquipediaMediaWikiMessages/workflows/Code%20Style/badge.svg)

Lua Modules are an integral part of Liquipedia. They allow for more complex logic for rendering elements.
Any modules added in this repository will, after a review process, be added to the modules and templates of the website.

**Note:** Modules in this repository are only a subset of those on the website. Any 'duplicates' on the website will be overwritten by those in this repository.

## Contributing

### Setup

Everything runs in a [devcontainer](https://containers.dev/). You install Docker and VS Code, then open the repo inside the container. First time it may take 5 minutes to start.

#### 1. Install Docker

**Linux**

Docker Engine
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker "$USER"
```

Log out and back in, or `docker` says permission denied.

**macOS**
[Docker Desktop](https://www.docker.com/products/docker-desktop/)
OR
```bash
brew install --cask docker
```

**Windows**
- [WSL 2](https://learn.microsoft.com/en-us/windows/wsl/install)
- then [Docker Desktop](https://www.docker.com/products/docker-desktop/) with the WSL 2 backend enabled.

#### 2. Install VS Code

1. [VS Code](https://code.visualstudio.com/download).
2. The [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension.

Nothing else — recommended extensions install themselves inside the container.

#### 3. Clone the repo

**Linux / macOS:**

```bash
git clone https://github.com/Liquipedia/Lua-Modules.git
```

**Windows**

Clone inside WSL, not on the Windows drive! Otherwise it will be super slow.
```bash
wsl
git clone https://github.com/Liquipedia/Lua-Modules.git ~/Lua-Modules
```

#### 4. Open it in the container

1. Open the folder in VS Code. On Windows run `code ~/Lua-Modules` from inside WSL.
2. Click **Reopen in Container** on the prompt, or press <kbd>F1</kbd> and pick *Dev Containers: Reopen in Container*.
3. Wait for the build. It then installs dependencies, builds the CSS and JS, and creates `.env` for you.

#### 5. Check it works

In the container terminal:

```bash
npm run lua-test
```

All tests should pass. You are done.

#### Without VS Code

```bash
npm install -g @devcontainers/cli
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . npm run lua-test
```

JetBrains IDEs can also open a devcontainer directly.

### Previewing CSS and JS changes on the live wiki

The container ships [mitmproxy](https://mitmproxy.org/) and `scripts/proxy_lp.py`, which serves your local `lua/output/css/main.css` and `lua/output/js/main.js` instead of the ones liquipedia.net would load. Background: [wiki page](https://github.com/Liquipedia/Lua-Modules/wiki/Local-Development-Setup-for-CSS-and-JS).

1. Run `npm run build`, so there is something to serve.
2. Start the proxy: `python scripts/proxy_lp.py` from the repo root, or the *Launch proxy* task in `.vscode/tasks.json`. It listens on `127.0.0.1:8080` on your host, so keep that port free.
3. Point your browser at that proxy. A switcher extension such as Proxy SwitchyOmega (HTTP, `127.0.0.1`, port `8080`) makes it easy to toggle; a system proxy setting works too.
4. With the proxy on, open <http://mitm.it> and install the certificate, so the browser trusts the intercepted HTTPS. Once only — the CA is kept in a volume.
5. Edit `.scss` or `.js`, run `npm run build`, hard refresh (<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>R</kbd> / <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>R</kbd>).

Turn the proxy off when you are done — while it is on, every request goes through the container.

### Adding a module

Modules start with a header like:

```
---
-- @Liquipedia
-- page=Module:$NameOfModule
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
```

The header is important, it is used by our automation to place a module in the correct location on the wikis.
The page is like the path. It determines where within the wiki the file is deployed/hosted. Other files refer to each other based on this path.

## Project

The project is divided into folders based on language. Even though the project is called Lua-Modules, a part of this repository is in different languages/techniques.

- In the `javascript` folder are scripts that run in the client. Our current setup does not fully support all available features in html. So for example a dropdown (select) element can't be rendered from our back end properly. We use javascript to add these kind of features. Essentially anything that makes an element interactable, buttons mostly, are constructed or configured from javascript.
- The modules written in lua are found in the `lua` folder.
  - Some modules are covered by unit tests. Tests are placed in the `spec` sub-folder.
- Styling is found in the `stylesheets` folder. For styling we use [scss](https://sass-lang.com/). Check out their documentation for getting up to speed on how this differs from traditional css.

### Automated Testing

#### Javascript & Stylesheets

```bash
npm run test:js   # jest
npm run lint      # eslint and stylelint
```

`npm run lint` fixes what eslint can fix on its own.

#### Lua

Run `npm run lua-test` in the root folder.

#### Visual Snapshot Testing

This project uses visual snapshot testing to verify UI components. Snapshots are automatically
generated and updated by our CI pipeline to ensure consistency across platforms.

- You don't need to update snapshots locally
- Submit your PR, and our CI will automatically update snapshots if needed
- The updated snapshots will be committed back to your PR branch
- Review the snapshot changes as part of your PR review process


## Committing changes

You need to be a member of the Liquipedia organization before you are allowed to push to this repository. In most workflows, you will make a fork of this repository to your own repository, and request a merge request from there. See the wiki for a step-by-step guide on how to commit a change.
Trusted contributers may be given the privilege of directly branching within the repository. These privileges are always up to the discretion of Liquipedia staff.

### Testing your branch

Deploying your branch to a dev environment publishes your modules to sandbox pages (suffixed with `/dev/<name>`) on the wiki, so you can render and test them without touching the live pages.

#### Via a GitHub Action

To test your changes in action, you can run the GitHub Action called "Personal Deploy" defined in `.github/workflows/deploy test.yml`. You can do it either through the GitHub interface or with the GitHub CLI tools:
`gh workflow run 'deploy test.yml' -r <BRANCH NAME> -f luadevenv=<DEV-ENV-NAME>`

To check the workflow progress from the CLI, you can run:
`gh run list --workflow="deploy test.yml"`

#### From your machine

You can also run the deploy script locally. This works from any editor — the repo ships a Visual Studio Code integration, and every other editor can call the same script directly.

**One-time setup:** the container already installed the Python dependencies and created `.env`. Fill in your bot credentials there. It is git-ignored — never commit it. It ships with `DRY_RUN=1`, so nothing reaches the wiki until you change that.

```
WIKI_BASE_URL=https://liquipedia.net
WIKI_UA_EMAIL=you@example.com
WIKI_USER=YourBotAccount@BotName
WIKI_PASSWORD=YourBotPassword
DRY_RUN=0
```

**Running it:**

```bash
# Deploy specific files
python scripts/deploy.py lua/wikis/commons/SomeModule.lua [more files...]

# Deploy every file changed on your branch under lua/wikis/
python scripts/deploy.py
```

The behaviour is driven by environment variables (set them in `.env` or per-invocation):

| Variable | Purpose |
| --- | --- |
| `LUA_DEV_ENV_NAME` | Sandbox suffix, e.g. `/dev/myenv`. Appended to every deployed page name. **Set this for all dev testing** — without it, deploys go to the live module pages. Also required to enable the no-argument "all changed files" mode. |
| `LUA_DEV_BASE_REF` | Ref that the no-argument mode diffs against to find changed files. Defaults to `main`. |
| `DRY_RUN` | Set to `1` to run the full flow without writing to the wiki. |
| `WIKI_USER` / `WIKI_PASSWORD` / `WIKI_BASE_URL` / `WIKI_UA_EMAIL` | Bot credentials and target wiki (see setup above). |

> **Note:** running `python scripts/deploy.py` with no arguments **and** no `LUA_DEV_ENV_NAME` triggers a full re-sync of every module to the live wiki — this is the automated weekly-resync path and is not what you want for testing a branch.

**Visual Studio Code:** the repo includes tasks in `.vscode/tasks.json` — run *Tasks: Run Task* and pick **Deploy current file** or **Deploy all changed file**. Both prompt for the dev environment name and the base ref.

**Other editors:** bind a command to `python scripts/deploy.py` with the environment above. For example, a Neovim mapping can shell out to `python scripts/deploy.py <file>` with `LUA_DEV_ENV_NAME=/dev/<name>` set on the job's environment.

## Support

If you encounter any issues or have questions, feel free to open an issue on GitHub or reach out to the Liquipedia community for support.

## Acknowledgements

We would like to thank all the contributors who have helped in developing and maintaining this repository. Your efforts are greatly appreciated.

## License

Most of this repository follows the license of the textual content of [Liquipedia](https://liquipedia.net), check out [the license file for more information](LICENSE.md), unless otherwise stated in a README.md for a directory, or in the header of a file.
