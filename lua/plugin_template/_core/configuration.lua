--- All functions and data to help customize `plugin_template` for this user.
---
--- @module 'plugin_template._core.configuration'
---

local say_constant = require("plugin_template._commands.say.constant")

local M = {}

-- TODO: Make sure that function type-hints behave as expected even when
-- a partial configuration definition is given

--- @class PluginTemplateConfiguration
---     The user's customizations for this plugin.
--- @field commands PluginTemplateConfigurationCommands?
---     Customize the fallback behavior of all `:PluginTemplate` commands.

--- @class PluginTemplateConfigurationCommands
---     Customize the fallback behavior of all `:PluginTemplate` commands.
--- @field goodnight_moon PluginTemplateConfigurationGoodnightMoon?
---     The default values when a user calls `:PluginTemplate goodnight-moon`.
--- @field hello_world PluginTemplateConfigurationHelloWorld?
---     The default values when a user calls `:PluginTemplate hello-world`.

--- @class PluginTemplateConfigurationGoodnightMoon
---     The default values when a user calls `:PluginTemplate goodnight-moon`.
--- @field read PluginTemplateConfigurationGoodnightMoonRead?
---     The default values when a user calls `:PluginTemplate goodnight-moon read`.

--- @class PluginTemplateConfigurationGoodnightMoonRead
---     The default values when a user calls `:PluginTemplate goodnight-moon read`.
--- @field phrase string
---     The book to read if no book is given by the user.

--- @class PluginTemplateConfigurationHelloWorld
---     The default values when a user calls `:PluginTemplate hello-world`.
--- @field say PluginTemplateConfigurationHelloWorldSay?
---     The default values when a user calls `:PluginTemplate hello-world say`.

--- @class PluginTemplateConfigurationHelloWorldSay
---     The default values when a user calls `:PluginTemplate hello-world say`.
--- @field repeat number
---     A 1-or-more value. When 1, the phrase is said once. When 2+, the phrase
---     is repeated that many times.
--- @field style "lowercase" | "uppercase"
---     Control how the text is displayed. e.g. "uppercase" changes "hello" to "HELLO".

-- NOTE: Don't remove this line. It makes the Lua module much easier to reload
vim.g.loaded_plugin_template = false

local _DATA = {}
local _DEFAULTS = {
    commands = {
        goodnight_moon = { read = { phrase = "A good book" } },
        hello_world = {
            say = { ["repeat"] = 1, style = say_constant.Keyword.style.lowercase },
        },
    },
}

--- Setup `plugin_template` for the first time, if needed.
local function _initialize_data_if_needed()
    if vim.g.loaded_plugin_template then
        return
    end

    _DATA = vim.tbl_deep_extend("force", _DEFAULTS, vim.g.plugin_template_configuration or {})

    vim.g.loaded_plugin_template = true
end

--- Merge `data` with the user's current configuration.
---
--- @param data PluginTemplateConfiguration? All extra customizations for this plugin.
--- @return PluginTemplateConfiguration # The configuration with 100% filled out values.
---
function M.resolve_data(data)
    _initialize_data_if_needed()

    return vim.tbl_deep_extend("force", _DATA, data or {})
end

return M
