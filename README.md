- Add more CI checks (type-hinting and the like)
- Change the configuration stuff
- Update the README.md
- Update Makefile with more options


# A Neovim Plugin Template

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/ellisonleao/nvim-plugin-template/lint-test.yml?branch=main&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

A template repository for Neovim plugins.


## Using it
TODO: Is this still real? Maybe remove?

Via `gh`:

```
$ gh repo create my-plugin -p ellisonleao/nvim-plugin-template
```

Via github web page:

Click on `Use this template`

![template](https://docs.github.com/assets/cb-36544/images/help/repository/use-this-template-button.png)


## Features and structure
- 100% Lua
- Follows [nvim-best-practices](https://github.com/nvim-neorocks/nvim-best-practices)
- Fast start-up (the plugin is defer-loaded)
- Built-in subcommand support + auto-completion
- No external dependencies
- Unittests use the full power of native [busted](https://olivinelabs.com/busted)
- Github actions for:
  - check for formatting errors [StyLua](https://github.com/JohnnyMorganz/StyLua)
  - TODO: Add more checkers here
  - vimdocs autogeneration from README.md file
  - [luarocks](https://luarocks.org) auto-release (LUAROCKS_API_KEY secret configuration required)

## Commands
Here are some example commands:

TODO: Finish these

```vim
:PluginName hello-world say phrase "Hello, World!" --repeat=2 --style=lowercase
:PluginName goodnight-moon read
:PluginName goodnight-moon sleep
```


## Install
TODO Fill this out


## Plugin structure
TODO: Check this part

```
.
├── lua
│   ├── plugin_name
│   │   └── module.lua
│   └── plugin_name.lua
├── Makefile
├── plugin
│   └── plugin_name.lua
├── README.md
├── spec
│   └── plugin_name
│       └── plugin_name_spec.lua
```


## Tests
### Initialization
Run this line once before calling any `busted` command

```sh
eval $(luarocks path --lua-version 5.1 --bin)
```


### Running
Run all tests
```sh
busted .
```

TODO: Include more commands for the other types of tests
