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
1. Clone this template ![Clone this template](https://github.com/user-attachments/assets/dbcea52c-e1e4-4aef-a9b8-ac5d7405f7ca)
(Or use `gh repo create nvim-best-practices-plugin-template -p ColinKennedy/nvim-best-practices-plugin-template`)

2. Enable GitHub repository permissions for various features

    - For auto-releases to LuaRocks, see [Releases](#releases)
    - For documentation auto-generation, see [Documentation](#documentation)

3. Replace all instances of the name of this plugin with your desired named

```sh
# Rename all files
git mv lua/plugin_template lua/your_plugin
git mv lua/telescope/_extensions/plugin_template lua/telescope/_extensions/your_plugin
git mv spec/plugin_template spec/your_plugin
find $PWD -type f | grep -v .git/ | xargs -I{} sh -c "rename --filename 's/nvim-best-practices-plugin-template/your-plugin.nvim/g ; s/plugin-template/your-plugin/ ; s/PluginTemplate/YourPlugin/ ; s/plugin_template/your_plugin/ ; s/ColinKennedy/YourUsername/' {}"

# Rename all file contents
find . -type f | grep -v .git/ | xargs sed -i 's/nvim-best-practices-plugin-template/your-plugin.nvim/g ; s/plugin-template/your-plugin/ ; s/PluginTemplate/YourPlugin/ ; s/plugin_template/your_plugin/ ; s/ColinKennedy/YourUsername/'
```

4. Remove any features that you don't need.

In general that means

- Replacing / removing anything in this file that you don't need or want
- Anything you remove here should be removed in the `lua/` directory, too
- Make sure the `plugin/` directory implements the command(s) and mappings that you need
- Remove plugin integrations if you don't want them:

- Removing [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) (if you don't want it)
```sh
rm -rf lua/lualine
rm configuration_tools_lualine_spec.lua
rm lualine_spec.lua
```
- Removing [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (if you don't want it)
```sh
rm -rf lua/telescope
rm configuration_tools_telescope_spec.lua
rm telescope_spec.lua
```

- Removing the built-in commands (if you don't want them):

```sh
rm -rf lua/plugin_template/_commands
```

5. Search for "TODO: (you)" in all files and fill them out
```sh
grep --recursive --line-number --word-regexp 'TODO: (you)' | nvim -q - -c "copen"
```

6. Add your plugin needs (commands, unittests, etc). Make sure tests pass (See
   `Tests`, below)

7. After you're done with the above, delete this section of the README.


## Releases
To enable automatic uploads to [LuaRocks](https://luarocks.org), you must:

1. Create a [LuaRocks API key](https://luarocks.org/settings/api-keys)
2. Add the secret API key to your GitHub actions (see below)
![image](https://github.com/user-attachments/assets/a0cadfa2-50e0-467e-99ea-55b4061e851e)
3. Add a new git tag and push the tag to the default (main) branch.

Example:

```sh
git checkout main
git tag -a v1.2.3 -m "Added an important bug fix"
git push --tags
```

[release.yml](.github/workflows/release.yml) will then make a release for you.


## Documentation
This template can auto-generate its own documentation and Vimtags. This is
controlled by the [documentation.yml](.github/workflows/documentation.yml) file.

For this feature to work, the GitHub workflow must have write access to the repository. To enable it:

- Click the Settings tab
- (Under the "Code and automation" section) Press "Actions" > "General"
- (In the new page) (Under "Workflow permissions") Press "Read and write permissions"

![image](https://github.com/user-attachments/assets/2eab9eaf-1696-4b32-be95-c891c2cc6adc)

You can also disable this feature by removing
[documentation.yml](.github/workflows/documentation.yml).


# Installation
<!-- TODO: (you) - Adjust and add your dependencies as needed here -->
- [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "ColinKennedy/nvim-best-practices-plugin-template",
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
