--- Tell the user which command they just ran, using lualine.nvim
---
---@source https://github.com/nvim-lualine/lualine.nvim
---
---@module 'lualine.components.plugin_template'
---

local arbitrary_thing_runner = require("plugin_template._commands.arbitrary_thing.runner")
local configuration = require("plugin_template._core.configuration")
local copy_log_runner = require("plugin_template._commands.copy_logs.runner")
local count_sheep = require("plugin_template._commands.goodnight_moon.count_sheep")
local lualine_require = require("lualine_require")
local modules = lualine_require.lazy_require({ highlight = "lualine.highlight" })
local read = require("plugin_template._commands.goodnight_moon.read")
local say_runner = require("plugin_template._commands.hello_world.say.runner")
local sleep = require("plugin_template._commands.goodnight_moon.sleep")
local tabler = require("plugin_template._core.tabler")

local M = require("lualine.component"):extend()

---@type string?
M.PREVIOUS_COMMAND = nil

---@class plugin_template.LualineConfiguration
---    The Raw user settings from lualine's configuration.
---    e.g. `require("lualine").setup { sections = { { "plugin_template", ... }}}`
---    where "..." is the user's settings.
---@field display table<string, plugin_template.LualineDisplayData>?

---@class plugin_template.LualineDisplayData
---    Any text, icons, etc that will be displayed for `plugin_template` commands.
---@field prefix string
---    The text to display when a command was called. e.g. " Goodnight moon".

--- Track the given `command` any time a function (`callers`) in `module` runs.
---
--- Warning:
---    To prevent unwanted behavior, only call this function one for every
---    unique Lua `module` + caller.
---
---@param module table<any, any> A Lua file to directly edit.
---@param callers string[] The names of each function(s) to modify.
---@param command string The command name to track when a function `callers` runs.
---
local function _patch_runner_commands(module, callers, command)
    for _, name in ipairs(callers) do
        local original_caller = module[name]

        module[name] = function(...)
            M.PREVIOUS_COMMAND = command

            return original_caller(...)
        end
    end
end

_patch_runner_commands(arbitrary_thing_runner, { "run" }, "arbitrary_thing")
_patch_runner_commands(copy_log_runner, { "run" }, "copy_logs")
_patch_runner_commands(count_sheep, { "run" }, "goodnight_moon")
_patch_runner_commands(read, { "run" }, "goodnight_moon")
_patch_runner_commands(say_runner, { "run_say_phrase", "run_say_word" }, "hello_world")
_patch_runner_commands(sleep, { "run" }, "goodnight_moon")

--- Setup all colors / text for lualine to display later.
---
---@param options plugin_template.LualineConfiguration?
---    The options to pass from lualine to `plugin_templaet`.
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
        arbitrary_thing = tabler.get_value(defaults, { "arbitrary_thing", "text" })
            or "<No Arbitrary Thing text was found>",
        copy_logs = tabler.get_value(defaults, { "copy_logs", "text" }) or "<No Copy Logs text was found>",
        hello_world = tabler.get_value(defaults, { "hello_world", "text" }) or "<No Hello World text was found>",
        goodnight_moon = tabler.get_value(defaults, { "goodnight_moon", "text" })
            or "<No Goodnight moon text was found>",
    }

    self._highlight_groups = {
        arbitrary_thing = modules.highlight.create_component_highlight_group(
            defaults.arbitrary_thing.color or "Visual",
            "plugin_template_arbitrary_thing",
            self.options
        ),
        copy_logs = modules.highlight.create_component_highlight_group(
            defaults.copy_logs.color or "Comment",
            "plugin_template_copy_logs",
            self.options
        ),
        goodnight_moon = modules.highlight.create_component_highlight_group(
            defaults.goodnight_moon.color or "Question",
            "plugin_template_goodnight_moon",
            self.options
        ),
        hello_world = modules.highlight.create_component_highlight_group(
            defaults.hello_world.color or "Title",
            "plugin_template_hello_world",
            self.options
        ),
    }
end

---@return string? # Get the text for the Lualine component.
function M:update_status()
    local command = M.PREVIOUS_COMMAND

    if not command then
        return nil
    end

    local text = self._command_text[command]
    local color = self._highlight_groups[M.PREVIOUS_COMMAND]

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
