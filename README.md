# 🚧 Under Construction 🚧

This repository doesn't have all GitHub CI actions working yet but is available
as an early preview. We will update docs/news.txt once it's ready.

Add https://github.com/ColinKennedy/nvim-best-practices-plugin-template/commits/main/doc/news.txt.atom
to your RSS feed so you don't miss it!

# A Neovim Plugin Template

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/ColinKennedy/nvim-best-practices-plugin-template/test.yml?branch=main&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

A template repository for Neovim plugins.


# Features
- Follows [nvim-best-practices](https://github.com/nvim-neorocks/nvim-best-practices)
- Fast start-up (the plugin is defer-loaded)
- Auto-release to [luarocks](https://luarocks.org)
- Automated documentation + Vimtags generation
- Built-in Vim commands
- A high quality command mode parser
- A (experimental) auto-completion API
- No external dependencies
- [LuaCATS](https://luals.github.io/wiki/annotations/) annotations and type-hints, everywhere
- RSS feed support
- Built-in logging to stdout / files
- Unittests use the full power of native [busted](https://olivinelabs.com/busted)
- 100% Lua
- Uses [Semantic Versioning](https://semver.org)
- Integrations
    - [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
    - [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
    - `:checkhealth`
- Github actions for:
    - [StyLua](https://github.com/JohnnyMorganz/StyLua) - Auto-formats Lua code
    - [llscheck](https://github.com/jeffzi/llscheck) - Checks for Lua type mismatches
    - [luacheck](https://github.com/mpeterv/luacheck) - Checks for Lua code issues
    - [luarocks](https://luarocks.org) auto-release (LUAROCKS_API_KEY secret configuration required)
    - [panvimdoc](https://github.com/kdheepak/panvimdoc) - Documentation auto-generator
    - PR reviews - Reminds users to update `doc/news.txt`


# Using This Template
1. Follow the [Wiki instructions](https://github.com/ColinKennedy/nvim-best-practices-plugin-template/wiki/Using-This-Template)
2. Once you're done, remove this section (the rest of this README.md file should be kept)


# Installation
<!-- TODO: (you) - Adjust and add your dependencies as needed here -->
- [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "ColinKennedy/nvim-best-practices-plugin-template",
    -- TODO: (you) - Make sure your first release matches v1.0.0 so it auto-releases!
    version = "v1.*",
}
```


# Configuration

(These are default values)

- [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "ColinKennedy/nvim-best-practices-plugin-template",
    config = function()
        vim.g.plugin_template_configuration = {
            commands = {
                goodnight_moon = { read = { phrase = "A good book" } },
                hello_world = {
                    say = { ["repeat"] = 1, style = "lowercase" },
                },
            },
            logging = {
                level = "info",
                use_console = false,
                use_file = false,
            },
            tools = {
                lualine = {
                    arbitrary_thing = {
                        color = "Visual",
                        text = " Arbitrary Thing",
                    },
                    copy_logs = {
                        color = "Comment",
                        text = "󰈔 Copy Logs",
                    },
                    goodnight_moon = {
                        color = "Question",
                        text = " Goodnight moon",
                    },
                    hello_world = {
                        color = "Title",
                        text = " Hello, World!",
                    },
                },
                telescope = {
                    goodnight_moon = {
                        { "Foo Book", "Author A" },
                        { "Bar Book Title", "John Doe" },
                        { "Fizz Drink", "Some Name" },
                        { "Buzz Bee", "Cool Person" },
                    },
                    hello_world = { "Hi there!", "Hello, Sailor!", "What's up, doc?" },
                },
            },
        }
    end
}
```


## Lualine

> Note: You can customize lualine colors here or using
> `vim.g.plugin_template_configuration`.

[lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
```lua
require("lualine").setup {
    sections = {
        lualine_y = {
            -- ... Your other configuration ...
            {
                "plugin_template",
                -- NOTE: These will override default values
                -- display = {
                --     goodnight_moon = {color={fg="#FFFFFF"}, text="Custom message 1"}},
                --     hello_world = {color={fg="#333333"}, text="Custom message 2"},
                -- },
            },
        }
    }
}
```


## Telescope

> Note: You can customize telescope colors here or using
> `vim.g.plugin_template_configuration`.

[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
```lua
{
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    config = function()
        -- ... Your other configuration ...
        require("telescope").load_extension("plugin_template")
    end,
    dependencies = {
        "ColinKennedy/nvim-best-practices-plugin-template",
        "nvim-lua/plenary.nvim",
    },
    version = "0.1.*",
},
```


## Colors
This plugin provides two default highlights

- PluginTemplateTelescopeEntry
- PluginTemplateTelescopeSecondary

Both come with default colors that should look nice. If you want to change them, here's how:
```lua
vim.api.nvim_set_hl(0, "PluginTemplateTelescopeEntry", {link="Statement"})
vim.api.nvim_set_hl(0, "PluginTemplateTelescopeSecondary", {link="Question"})
```


# Commands
Here are some example commands:

<!-- TODO: (you) - You'll probably want to change all this or remove it. See -->
<!-- plugin/plugin_template.lua for details. -->

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


# Tests
## Initialization
Run this line once before calling any `busted` command

```sh
eval $(luarocks path --lua-version 5.1 --bin)
```


## Running
Run all tests
```sh
busted .
```

Run test based on tags
```sh
busted . --tags=simple
```

# Tracking Updates
See [doc/news.txt](doc/news.txt) for updates.

You can add changes to this plugin by adding this URL to your RSS feed:
```
https://github.com/ColinKennedy/nvim-best-practices-plugin-template/commits/main/doc/news.txt.atom
```

# Other Plugins
This template is full of various features. But if your plugin is only meant to
be a simple plugin and you don't want the bells and whistles that this template
provides, consider instead using
[nvim-plugin-template](https://github.com/ellisonleao/nvim-plugin-template)
