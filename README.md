# A Neovim Plugin Template

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/ColinKennedy/nvim-plugin-template/test.yml?branch=main&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

A template repository for Neovim plugins.


# Features
- Follows [nvim-best-practices](https://github.com/nvim-neorocks/nvim-best-practices)
- Fast start-up (the plugin is defer-loaded)
- Built-in Vim commands with auto-completion
- No external dependencies
- [LuaCATS](https://luals.github.io/wiki/annotations/) annotations and type-hints, everywhere
- RSS feed support
- Unittests use the full power of native [busted](https://olivinelabs.com/busted)
- 100% Lua
- Integrations
    - [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
    - [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
    - `:checkhealth`
- Github actions for:
    - PR reviews - Reminds users to update `doc/news.txt`
    - [StyLua](https://github.com/JohnnyMorganz/StyLua) - Auto-formats Lua code
    - [llscheck](https://github.com/jeffzi/llscheck) - Checks for Lua type mismatches
    - [luacheck](https://github.com/mpeterv/luacheck) - Checks for Lua code issues
    - [luarocks](https://luarocks.org) auto-release (LUAROCKS_API_KEY secret configuration required)
    - [panvimdoc](https://github.com/kdheepak/panvimdoc) - Documentation auto-generator

# Using This Template
1. Clone this template ![Clone this template](https://github.com/user-attachments/assets/a366825c-aeb1-4b8a-971d-bba7ee3c61d7)
(Or use `gh repo create your-plugin -p ColinKennedy/nvim-best-practices-plugin-template`)

2. Replace all instances of the name of this plugin with your desired named

TODO: test this command, make sure it works
```sh
find . -type f -print0 | xargs -0 sed -i 's/PluginTemplate/YourPlugin/g ; s/plugin_template/your_plugin/g ; s/plugin-template/your-plugin/g s/nvim-best-practices-plugin-template/your-plugin.nvim/g ; s/ColinKennedy/YourUsername/g'
```

3. Remove any features that you don't need (people like integrations, keep them
if you think you can use them! Adapt these integrations for your plugin)
    TODO: Add these unittests
    - Removing [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
    ```sh
    rm -rf lua/lualine
    rm configuration_tools_lualine_spec.lua
    rm lualine_spec.lua
    ```
    - Removing [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
    ```sh
    rm -rf lua/lualine
    TODO: Add this test
    rm configuration_tools_telescope_spec.lua
    ```

4. Search for "TODO: (you)" in all files and fill them out
```sh
grep --recursive --line-number --word-regexp 'TODO: (you)' | nvim -q - -c "copen"
```

5. After you're done with the above, delete this section of the README.

# Installation
<!-- TODO: (you) - Add your dependencies as needed here -->
- [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "ColinKennedy/nvim-best-practices-plugin-template",
}
```

## Configuration

(These are default values)
TODO: Make sure this is up to date and works
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
                    goodnight_moon = { color = { link = "Comment" }, text = " Goodnight moon" },
                    hello_world = { color = { link = "Title" }, text = " Hello, World!" },
                },
                telescope = {
                    -- goodnight_moon = {"Foo Book", "Bar Book Title" },
                    hello_world = { "Hi there!" },
                },
            }
        }
    end
}
```

## Lualine
- [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
```lua
require("lualine").setup {
    sections = {
        lualine_y = {
            -- ... Your other configuration ...
            {
                "plugin_template",
                -- NOTE: These override default values
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

TODO: Make sure these work

- PluginTemplateTelescopeEntry
- PluginTemplateTelescopeSecondary

Both come with default colors that should look nice. If you want to change them, here's how:
```lua
vim.api.nvim_set_hl(0, "PluginTemplateTelescopeEntry", {link="Statement"})
vim.api.nvim_set_hl(0, "PluginTemplateTelescopeSecondary", {link="Question"})
```


## Commands
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

# News
TODO: Add relative link
See doc/news.txt for updates.

You can add changes to this plugin by adding this URL to your RSS feed:
```
https://github.com/ColinKennedy/nvim-best-practices-plugin-template/commits/main/doc/news.txt.atom
```
