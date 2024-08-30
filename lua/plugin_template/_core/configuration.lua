--- All functions and data to help customize `plugin_template` for this user.
---
--- @module 'plugin_template._core.configuration'
---

local say_constant = require("plugin_template._commands.hello_world.say.constant")

--- @alias vim.log.levels.DEBUG number Messages to show to plugin maintainers.
--- @alias vim.log.levels.ERROR number Unrecovered issues to show to the plugin users.
--- @alias vim.log.levels.INFO number Informative messages to show to the plugin users.
--- @alias vim.log.levels.TRACE number Low-level or spammy messages.
--- @alias vim.log.levels.WARN number An error that was recovered but could be an issue.

--- @class plugin_template.Configuration
---     The user's customizations for this plugin.
--- @field commands plugin_template.ConfigurationCommands?
---     Customize the fallback behavior of all `:PluginTemplate` commands.
--- @field logging plugin_template.LoggingConfiguration?
---     Control how and which logs print to file / Neovim.
--- @field tools plugin_template.ConfigurationTools?
---     Optional third-party tool integrations.

--- @class plugin_template.ConfigurationCommands
---     Customize the fallback behavior of all `:PluginTemplate` commands.
--- @field goodnight_moon plugin_template.ConfigurationGoodnightMoon?
---     The default values when a user calls `:PluginTemplate goodnight-moon`.
--- @field hello_world plugin_template.ConfigurationHelloWorld?
---     The default values when a user calls `:PluginTemplate hello-world`.

--- @class plugin_template.ConfigurationGoodnightMoon
---     The default values when a user calls `:PluginTemplate goodnight-moon`.
--- @field read plugin_template.ConfigurationGoodnightMoonRead?
---     The default values when a user calls `:PluginTemplate goodnight-moon read`.

--- @class plugin_template.LoggingConfiguration
---     Control whether or not logging is printed to the console or to disk.
--- @field level (
---     | "trace"
---     | "debug"
---     | "info"
---     | "warn"
---     | "error"
---     | "fatal"
---     | vim.log.levels.DEBUG
---     | vim.log.levels.ERROR
---     | vim.log.levels.INFO
---     | vim.log.levels.TRACE
---     | vim.log.levels.WARN)?
---     Any messages above this level will be logged.
--- @field use_console boolean?
---     Should print the output to neovim while running. Warning: This is very
---     spammy. You probably don't want to enable this unless you have to.
--- @field use_file boolean?
---     Should write to a file.

--- @class plugin_template.ConfigurationGoodnightMoonRead
---     The default values when a user calls `:PluginTemplate goodnight-moon read`.
--- @field phrase string
---     The book to read if no book is given by the user.

--- @class plugin_template.ConfigurationHelloWorld
---     The default values when a user calls `:PluginTemplate hello-world`.
--- @field say plugin_template.ConfigurationHelloWorldSay?
---     The default values when a user calls `:PluginTemplate hello-world say`.

--- @class plugin_template.ConfigurationHelloWorldSay
---     The default values when a user calls `:PluginTemplate hello-world say`.
--- @field repeat number
---     A 1-or-more value. When 1, the phrase is said once. When 2+, the phrase
---     is repeated that many times.
--- @field style "lowercase" | "uppercase"
---     Control how the text is displayed. e.g. "uppercase" changes "hello" to "HELLO".

--- @class plugin_template.ConfigurationTools
---     Optional third-party tool integrations.
--- @field lualine plugin_template.ConfigurationToolsLualine?
---     A Vim statusline replacement that will show the command that the user just ran.

--- @alias plugin_template.ConfigurationToolsLualine table<string, plugin_template.ConfigurationToolsLualineData>
---     Each runnable command and its display text.

--- @class plugin_template.ConfigurationToolsLualineData
---     The display values that will be used when a specific `plugin_template`
---     command runs.
--- @diagnostic disable-next-line: undefined-doc-name
--- @field color vim.api.keyset.highlight?
---     The foreground/background color to use for the Lualine status.
--- @field prefix string?
---     The text to display in lualine.

local vlog = require("plugin_template._vendors.vlog")

local M = {}

-- NOTE: Don't remove this line. It makes the Lua module much easier to reload
vim.g.loaded_plugin_template = false

M.DATA = {}

local _DEFAULTS = {
    commands = {
        goodnight_moon = { read = { phrase = "A good book" } },
        hello_world = {
            say = { ["repeat"] = 1, style = say_constant.Keyword.style.lowercase },
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
                -- color = { link = "#D3D3D3" },
                color = "Comment",
                text = "󰈔 Copy Logs",
            },
            goodnight_moon = {
                -- color = { fg = "#0000FF" },
                color = "Question",
                text = " Goodnight moon",
            },
            hello_world = {
                -- color = { fg = "#FFA07A" },
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

--- Setup `plugin_template` for the first time, if needed.
function M.initialize_data_if_needed()
    if vim.g.loaded_plugin_template then
        return
    end

    M.DATA = vim.tbl_deep_extend("force", _DEFAULTS, vim.g.plugin_template_configuration or {})

    vim.g.loaded_plugin_template = true

    vlog.new(M.DATA.logging or {}, true)

    vlog.fmt_debug("Initialized plugin-template's configuration.")
end

--- Merge `data` with the user's current configuration.
---
--- @param data plugin_template.Configuration? All extra customizations for this plugin.
--- @return plugin_template.Configuration # The configuration with 100% filled out values.
---
function M.resolve_data(data)
    M.initialize_data_if_needed()

    return vim.tbl_deep_extend("force", M.DATA, data or {})
end

return M
