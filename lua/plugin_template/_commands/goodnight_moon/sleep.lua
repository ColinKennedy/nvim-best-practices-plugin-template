--- The main file that implements `goodnight-moon sleep` outside of COMMAND mode.

local logging = require("mega.logging")

local _LOGGER = logging.get_logger("plugin_template._commands.goodnight_moon.sleep")

local M = {}

--- Print Zzz each `count`.
---
---@param count number? Prints 1 Zzz per `count`. A value that is 1-or-greater.
---
function M.run(count)
    _LOGGER:debug("Running goodnight-moon count-sheep")

    if count == nil then
        count = 1
    end

    if count < 1 then
        _LOGGER:fmt_warning('count-sheep "%s" is invalid. Setting the value to to 1-or-greater, instead.', count)

        count = 1
    end

    for _ = 1, count do
        vim.notify("Zzz", vim.log.levels.INFO)
    end
end

return M
