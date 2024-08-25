TODO: Add this
- Update the README.md
- Update Makefile with more options


TODO: Show how to do lualine via code


# A Neovim Plugin Template

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/ellisonleao/nvim-plugin-template/lint-test.yml?branch=main&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

A template repository for Neovim plugins.

lualine
```lua
{
    display = {color="TODO", text="Some text"}
}
-- {"plugin_template"}
{
    "plugin_template",
    display = {
        goodnight_moon = {color={fg="#FFFFFF"}, text="AAAA"},
        hello_world = {color={fg="#333333"}, text="TTTT"},
    },
},
```

Telescope
```lua
require("telescope").load_extension("plugin_template")
```
- color customization - "TelescopeResultsNormal"}, { entry.author, "TelescopeResultsComment" } })


TODO
```lua
{
    'ColinKennedy/nvim-best-practices-plugin-template',
    -- cmd = "PluginTemplate",
    config = false,
    directory = "/home/selecaoone/repositories/personal/.config/nvim/bundle/nvim-best-practices-plugin-template",
}
```


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
:PluginTemplate hello-world say phrase "Hello, World!" " How are you?"
:PluginTemplate hello-world say phrase "Hello, World!" --repeat=2 --style=lowercase

" An example of a flag this repeatable and 3 flags, -a, -b, -c, as one dash
:PluginTemplate hello-world arbitrary-thing -vvv -abc -f

" Separate commands with completely separate, flexible APIs
:PluginTemplate goodnight-moon count-sheep 42
:PluginTemplate goodnight-moon read "a book"
:PluginTemplate goodnight-moon sleep -zzz
```

TODO: Make sure people know that api.lua is anything they'd like it to be


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
find -name "*.lua" -type f | xargs sed -i 's/plugin_template/your_plugin/g ; s/PluginTemplate/YourPlugin/g'
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
