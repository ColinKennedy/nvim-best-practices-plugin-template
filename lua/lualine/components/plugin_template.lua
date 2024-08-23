--- Tell the user which command they just ran, using lualine.nvim
---
--- @source https://github.com/nvim-lualine/lualine.nvim
---
--- @module 'lualine.components.plugin_template'
---

local configuration = require("plugin_template._core.configuration")
local lualine_require = require("lualine_require")
local modules = lualine_require.lazy_require({ highlight = "lualine.highlight" })
local state = require("plugin_template._core.state")
local tabler = require("plugin_template._core.tabler")

local M = require("lualine.component"):extend()

--- @class PluginTemplateLualineConfiguration
---     The Raw user settings from lualine's configuration.
---     e.g. `require("lualine").setup { sections = { { "plugin_template", ... }}}`
---     where "..." is the user's settings.
--- @field display table<string, PluginTemplateLualineDisplayData>?

--- @class PluginTemplateLualineDisplayData
---     Any text, icons, etc that will be displayed for `plugin_template` commands.
--- @field prefix string
---     The text to display when a command was called. e.g. " Goodnight moon".

--- Setup all colors / text for lualine to display later.
---
--- @param options PluginTemplateLualineConfiguration?
---     The options to pass from lualine to `plugin_templaet`.
---
function M:init(options)
    --- @type table<string, PluginTemplateLualineDisplayData>
    local data

    if options then
        data = options.display or {}
    end

    configuration.initialize_data_if_needed()
    local defaults = tabler.get_value(configuration.DATA, {"tools", "lualine"}) or {}
    defaults = vim.tbl_deep_extend("force", defaults, data)

    M.super.init(self, options)

    self._command_text = {
        hello_world = tabler.get_value(defaults, {"hello_world", "text"}) or "<No Hello World text was found>",
        goodnight_moon = tabler.get_value(defaults, {"goodnight_moon", "text"}) or "<No Goodnight moon text was found>",
    }

    self._highlight_groups = {
        goodnight_moon = modules.highlight.create_component_highlight_group(
            defaults.goodnight_moon.color or {link="Comment"},
            "plugin_template_goodnight_moon",
            self.options
        ),
        hello_world = modules.highlight.create_component_highlight_group(
            defaults.hello_world.color or {link="Title"},
            "plugin_template_hello_world",
            self.options
        ),
    }
end

--- @return string? # Get the text for the Lualine component.
function M:update_status()
    local command = state.PREVIOUS_COMMAND

    if not command then
        return nil
    end

    local text = self._command_text[command]
    local color = self._highlight_groups[state.PREVIOUS_COMMAND]

    if not color then
        return text
    end

    local prefix = modules.highlight.component_format_highlight(color)

    if not prefix then
        return text
    end

    return prefix .. text
end

return M