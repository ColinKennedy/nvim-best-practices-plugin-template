--- All functions and data to help customize `plugin_template` for this user.

local say_constant = require("plugin_template._commands.hello_world.say.constant")

local logging = require("mega.logging")

local _LOGGER = logging.get_logger("plugin_template._core.configuration")

local M = {}

-- NOTE: Don't remove this line. It makes the Lua module much easier to reload
vim.g.loaded_plugin_template = false

---@type plugin_template.Configuration
M.DATA = {}

-- TODO: (you) If you use the mega.logging module for built-in logging, keep
-- the `logging` section. Otherwise delete it.
--
-- It's recommended to keep the `display` section in any case.
--
---@type plugin_template.Configuration
local _DEFAULTS = {
    logging = { level = "info", use_console = false, use_file = false },
}

-- TODO: (you) Update these sections depending on your intended plugin features.
local _EXTRA_DEFAULTS = {
    commands = {
        goodnight_moon = { read = { phrase = "A good book" } },
        hello_world = {
            say = { ["repeat"] = 1, style = say_constant.Keyword.style.lowercase },
        },
    },
    tools = {
        lualine = {
            arbitrary_thing = {
                -- color = { link = "#555555" },
                color = "Visual",
                text = " Arbitrary Thing",
            },
            copy_logs = {
                -- color = { link = "#D3D3D3" },
                color = "Comment",
                text = "󰈔 Copy Logs",
            },
            goodnight_moon = {
                -- color = { fg = "#0000FF" },
                color = "Question",
                text = "⏾ Goodnight moon",
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

_DEFAULTS = vim.tbl_deep_extend("force", _DEFAULTS, _EXTRA_DEFAULTS)

--- Setup `plugin_template` for the first time, if needed.
function M.initialize_data_if_needed()
    if vim.g.loaded_plugin_template then
        return
    end

    M.DATA = vim.tbl_deep_extend("force", _DEFAULTS, vim.g.plugin_template_configuration or {})

    vim.g.loaded_plugin_template = true

    local configuration = M.DATA.logging or {}
    ---@cast configuration mega.logging.SparseLoggerOptions
    logging.set_configuration("plugin_template", configuration)

    _LOGGER:fmt_debug("Initialized plugin-template's configuration.")
end

--- Merge `data` with the user's current configuration.
---
---@param data plugin_template.Configuration? All extra customizations for this plugin.
---@return plugin_template.Configuration # The configuration with 100% filled out values.
---
function M.resolve_data(data)
    M.initialize_data_if_needed()

    return vim.tbl_deep_extend("force", M.DATA, data or {})
end

return M
