--- A collection of types to be included / used in other Lua files.
---
--- These types are either required by the Lua API or required for the normal
--- operation of this Lua plugin.
---
---@module 'plugin_template.types'
---

---@alias vim.log.levels.DEBUG number Messages to show to plugin maintainers.
---@alias vim.log.levels.ERROR number Unrecovered issues to show to the plugin users.
---@alias vim.log.levels.INFO number Informative messages to show to the plugin users.
---@alias vim.log.levels.TRACE number Low-level or spammy messages.
---@alias vim.log.levels.WARN number An error that was recovered but could be an issue.

---@class plugin_template.Configuration
---    The user's customizations for this plugin.
---@field cmdparse plugin_template.ConfigurationCmdparse?
---    All settings that control the command mode tools (parsing, auto-complete, etc).
---@field commands plugin_template.ConfigurationCommands?
---    Customize the fallback behavior of all `:PluginTemplate` commands.
---@field logging plugin_template.LoggingConfiguration?
---    Control how and which logs print to file / Neovim.
---@field tools plugin_template.ConfigurationTools?
---    Optional third-party tool integrations.

---@class plugin_template.ConfigurationCmdparse
---    All settings that control the command mode tools (parsing, auto-complete, etc).
---@field auto_complete plugin_template.ConfigurationCmdparseAutoComplete
---    The settings that control what happens during auto-completion.

---@class plugin_template.ConfigurationCmdparseAutoComplete
---    The settings that control what happens during auto-completion.
---@field display {help_flag: boolean}
---    help_flag = Show / Hide the --help flag during auto-completion.

---@class plugin_template.ConfigurationCommands
---    Customize the fallback behavior of all `:PluginTemplate` commands.
---@field goodnight_moon plugin_template.ConfigurationGoodnightMoon?
---    The default values when a user calls `:PluginTemplate goodnight-moon`.
---@field hello_world plugin_template.ConfigurationHelloWorld?
---    The default values when a user calls `:PluginTemplate hello-world`.

---@class plugin_template.ConfigurationGoodnightMoon
---    The default values when a user calls `:PluginTemplate goodnight-moon`.
---@field read plugin_template.ConfigurationGoodnightMoonRead?
---    The default values when a user calls `:PluginTemplate goodnight-moon read`.

---@class plugin_template.LoggingConfiguration
---    Control whether or not logging is printed to the console or to disk.
---@field level (
---    | "trace"
---    | "debug"
---    | "info"
---    | "warn" | "error"
---    | "fatal"
---    | vim.log.levels.DEBUG
---    | vim.log.levels.ERROR
---    | vim.log.levels.INFO
---    | vim.log.levels.TRACE
---    | vim.log.levels.WARN)?
---    Any messages above this level will be logged.
---@field use_console boolean?
---    Should print the output to neovim while running. Warning: This is very
---    spammy. You probably don't want to enable this unless you have to.
---@field use_file boolean?
---    Should write to a file.
---@field output_path string?
---    The default path on-disk where log files will be written to.
---    Defaults to "/home/selecaoone/.local/share/nvim/plugin_name.log".

---@class plugin_template.ConfigurationGoodnightMoonRead
---    The default values when a user calls `:PluginTemplate goodnight-moon read`.
---@field phrase string
---    The book to read if no book is given by the user.

---@class plugin_template.ConfigurationHelloWorld
---    The default values when a user calls `:PluginTemplate hello-world`.
---@field say plugin_template.ConfigurationHelloWorldSay?
---    The default values when a user calls `:PluginTemplate hello-world say`.

---@class plugin_template.ConfigurationHelloWorldSay
---    The default values when a user calls `:PluginTemplate hello-world say`.
---@field repeat number
---    A 1-or-more value. When 1, the phrase is said once. When 2+, the phrase
---    is repeated that many times.
---@field style "lowercase" | "uppercase"
---    Control how the text is displayed. e.g. "uppercase" changes "hello" to "HELLO".

---@class plugin_template.ConfigurationTools
---    Optional third-party tool integrations.
---@field lualine plugin_template.ConfigurationToolsLualine?
---    A Vim statusline replacement that will show the command that the user just ran.

---@alias plugin_template.ConfigurationToolsLualine table<string, plugin_template.ConfigurationToolsLualineData>
---    Each runnable command and its display text.

---@class plugin_template.ConfigurationToolsLualineData
---    The display values that will be used when a specific `plugin_template`
---    command runs.
---@diagnostic disable-next-line: undefined-doc-name
---@field color vim.api.keyset.highlight?
---    The foreground/background color to use for the Lualine status.
---@field prefix string?
---    The text to display in lualine.
