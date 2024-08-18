--- All functions and data to help customize `plugin_name` for this user.
---
--- @module 'plugin_name._core.configuration'
---

local M = {}

-- TODO: Make sure that function type-hints behave as expected even when
-- a partial configuration definition is given

--- @class PluginNameConfiguration
---     The user's customizations for this plugin.
--- @field commands PluginNameConfigurationCommands?
---     Customize the fallback behavior of all `:PluginName` commands.

--- @class PluginNameConfigurationCommands
---     Customize the fallback behavior of all `:PluginName` commands.
--- @field goodnight_moon PluginNameConfigurationGoodnightMoon?
---     The default values when a user calls `:PluginName goodnight-moon`.
--- @field hello_world PluginNameConfigurationHelloWorld?
---     The default values when a user calls `:PluginName hello-world`.

--- @class PluginNameConfigurationGoodnightMoon
---     The default values when a user calls `:PluginName goodnight-moon`.
--- @field read PluginNameConfigurationGoodnightMoonRead?
---     The default values when a user calls `:PluginName goodnight-moon read`.

--- @class PluginNameConfigurationGoodnightMoonRead
---     The default values when a user calls `:PluginName goodnight-moon read`.
--- @field phrase string
---     The book to read if no book is given by the user.

--- @class PluginNameConfigurationHelloWorld
---     The default values when a user calls `:PluginName hello-world`.
--- @field say PluginNameConfigurationHelloWorldSay?
---     The default values when a user calls `:PluginName hello-world say`.

--- @class PluginNameConfigurationHelloWorldSay
---     The default values when a user calls `:PluginName hello-world say`.
--- @field repeat number
---     A 1-or-more value. When 1, the phrase is said once. When 2+, the phrase
---     is repeated that many times.
--- @field style "lowercase" | "uppercase"
---     Control how the text is displayed. e.g. "uppercase" changes "hello" to "HELLO".

-- NOTE: Don't remove this line. It makes the Lua module much easier to reload
vim.g.loaded_plugin_name = false

local _DATA = {}
local _DEFAULTS = {
    commands = {
        goodnight_moon = { read = { phrase = "A good book" } },
        hello_world = { say = { ["repeat"] = 1, style = "lowercase" } },
    },
}

--- Setup `plugin_name` for the first time, if needed.
local function _initialize_data_if_needed()
    if vim.g.loaded_plugin_name then
        return
    end

    _DATA = vim.tbl_deep_extend("force", _DEFAULTS, vim.g.plugin_name_configuration or {})

    vim.g.loaded_plugin_name = true
end

--- Merge `data` with the user's current configuration.
---
--- @param data PluginNameConfiguration? All extra customizations for this plugin.
---
function M.resolve_data(data)
    _initialize_data_if_needed()

    return vim.tbl_deep_extend("force", _DATA, data or {})
end

return M
