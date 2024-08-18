TODO: Add this
- Update the README.md
- Update Makefile with more options


# A Neovim Plugin Template

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/ellisonleao/nvim-plugin-template/lint-test.yml?branch=main&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

A template repository for Neovim plugins.


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
" A typical subcommand
:PluginName hello-world say phrase "Hello, World!" " How are you?"
:PluginName hello-world say phrase "Hello, World!" --repeat=2 --style=lowercase

" An example of a flag this repeatable and 3 flags, -a, -b, -c, as one dash
:PluginName hello-world arbitrary-thing -vvv -abc -f

" Separate commands with completely separate, flexible APIs
:PluginName goodnight-moon read "a book"
:PluginName goodnight-moon count-sheep 42
:PluginName goodnight-moon sleep -zzz
```


## Using it
TODO: Is this still real? Maybe remove?

Via `gh`:

```
$ gh repo create my-plugin -p ellisonleao/nvim-plugin-template
```

Via github web page:

Click on `Use this template`

![template](https://docs.github.com/assets/cb-36544/images/help/repository/use-this-template-button.png)

TODO: Explain how to immediately make this template your own

```sh
find -name "*.lua" -type f | xargs sed -i 's/plugin_name/your_plugin/g ; s/PluginName/YourPlugin/g'
```


## Install
TODO Fill this out


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

Run a suite of tests
TODO: Write it

Run an individual test
TODO: Write it
