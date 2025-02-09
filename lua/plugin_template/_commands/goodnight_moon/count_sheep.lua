--- The main file that implements `goodnight-moon count-sheep` outside of COMMAND mode.

local configuration = require("plugin_template._core.configuration")
local logging = require("mega.logging")

local _LOGGER = logging.get_logger("plugin_template._commands.goodnight_moon.count_sheep")

local M = {}

--- Count a sheep for each `count`.
---
---@param count number Prints 1 sheep per `count`. A value that is 1-or-greater.
---
function M.run(count)
    configuration.initialize_data_if_needed()
    _LOGGER:debug("Running goodnight-moon count-sheep")

    if count < 1 then
        _LOGGER:fmt_warning('Count "%s" cannot be less than 1. Using 1 instead.', count)

        count = 1
    end

    for index = 1, count do
        vim.notify(string.format("%s Sheep", index), vim.log.levels.INFO)
    end
end

return M
