# Lua-Modules

![Code Style](https://github.com/Liquipedia/LiquipediaMediaWikiMessages/workflows/Code%20Style/badge.svg)

Lua Modules are an integral part of Liquipedia. They allow for more complex logic for rendering elements. The website supports adding and editing these modules straight from the browser. For more complex modules however, a more integrated developer environment has been requested by several users. To provide in this need this github repository has been constructed.
Any modules added in this repository will, after a review process, be added to the modules and templates of the website.

**Note:** Modules in this repository are only a subset off those on the website. Any 'duplicates' on the website will be overwritten by those in this repository.

## Contributing

If you want to contribute you may do that in any way you wish. We use the following steps for onboarding new developers.

### Setup

#### Dependencies Installation

Clone the repository. This requires [git](https://git-scm.com/downloads) to be installed on your system.

##### Windows

Recommended to use WSL. Then follow the Unix instructions.

##### Unix

TODO: Write

##### Mac

- Install Lua. We use version 5.1. There are some 5.2 features which are available, but nothing from 5.3 onwards. Using a newer version is not recommended or supported. The lua version is restricted as we use [LuaJit](https://luajit.org/). If you're [curious](https://github.com/LuaJIT/LuaJIT/issues/929).
  Using brew will warn you that lua 5.1 has been deprecated and installing is disabled. Can be installed by editing the file with `brew edit lua@5.1`. Remove the line that says `disable! date: "2022-07-31", because: :unmaintained`
  Finally run `HOMEBREW_NO_INSTALL_FROM_API=1 brew install lua@5.1` which will then install it anyway.
- Install the package manager, [LuaRocks](https://luarocks.org/) `brew install luarocks`
- The project contains two third party dependencies, busted and luacheck. Install both through luarocks
  - `luarocks install --lua-version=5.1 busted` <- used as a [testing framework](https://luarocks.org/modules/lunarmodules/busted)
  - `luarocks install --lua-version=5.1 luacheck` <- for [linting](https://luarocks.org/modules/mpeterv/luacheck)
  - Make sure the installed rocks are available in your Path variable. How to do this might depend on your choice of terminal.
  - Test if everything works by running `busted` from the command line in your projects root folder. If the tests run and are all green you should be good to go.
- Install an ide/texteditor of choice. The repo contains some presets for [Visual Studio Code](https://code.visualstudio.com/download).

#### IDE

##### Visual Studio Code

We recommend VSCode. Highly recommend that you get the extension [Lua](https://marketplace.visualstudio.com/items?itemName=sumneko.lua). The repo is setup with presets for this.

##### Intellij

Highly recommend that you get the extension [SumnekoLua](https://plugins.jetbrains.com/plugin/22315-sumnekolua).

### Adding a module

Modules start with a header like:

```
---
-- @Liquipedia
-- wiki=commons
-- page=Module:$NameOfModule
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
```

The header is important, it is used by our automation to place a module in the correct wiki (commons here, other values are dota2, deadlock, rainbowsix etc. See the [Api Docs](https://api.liquipedia.net/documentation/api/v3) under Available Wikis for all wikis).
The page is like the path. It determines where within the wiki the file is deployed/hosted. Other files refer to each other based on this path.

## Project

The project is divided into folders based on language. Even though the project is called Lua-Modules, a part of this repository is in different languages/techniques.

- In the javascript folder are scripts that run in the client. Our current setup does not fully support all available features in html. So for example a dropdown (select) element can't be rendered from our back end properly. We use javascript to add these kind of features. Essentially anything that makes an element interactable, buttons mostly, are constructed or configured from javascript.
- The modules written in lua are found in the `standard` or `components` folder.
  - Most(read:some) modules are covered by unit tests. Tests are placed in the spec folder.
- Styling is found in the stylesheets folder. For styling we use [less](https://lesscss.org/). Check out their documentation for getting up to speed on how this differs from traditional css.

## Committing changes

You need to be a member of the Liquipedia organization before you are allowed to push to this repository. In most workflows, you will make a fork of this repository to your own repository, and request a merge request from there.
Trusted contributers may be given the privilege of directly branching within the repository. These privileges are always up to the discretion of Liquipedia staff.

## Support

If you encounter any issues or have questions, feel free to open an issue on GitHub or reach out to the Liquipedia community for support.

## Acknowledgements

We would like to thank all the contributors who have helped in developing and maintaining this repository. Your efforts are greatly appreciated.

## License

Most of this repository follows the license of the textual content of [Liquipedia](https://liquipedia.net), check out [the license file for more information](LICENSE.md), unless otherwise stated in a README.md for a directory, or in the header of a file.