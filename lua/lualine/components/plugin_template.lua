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

--- @class plugin_template.LualineConfiguration
---     The Raw user settings from lualine's configuration.
---     e.g. `require("lualine").setup { sections = { { "plugin_template", ... }}}`
---     where "..." is the user's settings.
--- @field display table<string, plugin_template.LualineDisplayData>?

--- @class plugin_template.LualineDisplayData
---     Any text, icons, etc that will be displayed for `plugin_template` commands.
--- @field prefix string
---     The text to display when a command was called. e.g. " Goodnight moon".

--- Setup all colors / text for lualine to display later.
---
--- @param options plugin_template.LualineConfiguration?
---     The options to pass from lualine to `plugin_templaet`.
---
function M:init(options)
    configuration.initialize_data_if_needed()

    --- @type table<string, plugin_template.LualineDisplayData>
    local data

    if options then
        data = options.display or {}
    end

    local defaults = tabler.get_value(configuration.DATA, { "tools", "lualine" }) or {}
    defaults = vim.tbl_deep_extend("force", defaults, data)

    M.super.init(self, options)

    self._command_text = {
        copy_logs = tabler.get_value(defaults, { "copy_logs", "text" }) or "<No Copy Logs text was found>",
        hello_world = tabler.get_value(defaults, { "hello_world", "text" }) or "<No Hello World text was found>",
        goodnight_moon = tabler.get_value(defaults, { "goodnight_moon", "text" })
            or "<No Goodnight moon text was found>",
    }

    self._highlight_groups = {
        copy_logs = modules.highlight.create_component_highlight_group(
            { fg = "#333333" },
            "plugin_template_copy_logs",
            self.options
        ),
        goodnight_moon = modules.highlight.create_component_highlight_group(
            { fg = "#FFFFFF" },
            "plugin_template_goodnight_moon",
            self.options
        ),
        hello_world = modules.highlight.create_component_highlight_group(
            { fg = "#777777" },
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
