--- Tell the user which command they just ran, using lualine.nvim
---
--- @source https://github.com/nvim-lualine/lualine.nvim
---
--- @module 'lualine.components.plugin_template'
---

local configuration = require("plugin_template._core.configuration")
local state = require("plugin_template._core.state")
local lualine_require = require("lualine_require")
local modules = lualine_require.lazy_require({ highlight = "lualine.highlight" })

local M = {}

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

    M.super.init(self, vim.tbl_deep_extend("force", configuration.DATA.commands, data))

    self._highlight_groups = {}

    for _, name in ipairs(vim.tbl_keys(configuration.DATA.profiles)) do
        self._highlight_groups[name] =
            modules.highlight.create_component_highlight_group(
                name,
                string.format("plugin_template_%s", data),
                self.options
            )
    end
end

--- @return string? # Get the text for the Lualine component.
function M:update_status()
    local details = self._highlight_groups[state.PREVIOUS_COMMAND]

    if not details then
        return nil
    end

    local prefix = details.prefix or ""

    if not prefix then
        return nil
    end

    return modules.highlight.component_format_highlight(prefix) or ""
end

return M

