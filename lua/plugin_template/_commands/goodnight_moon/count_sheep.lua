--- The main file that implements `goodnight-moon count-sheep` outside of COMMAND mode.
---
---@module 'plugin_template._commands.goodnight_moon.count_sheep.runner'
---

local configuration = require("plugin_template._core.configuration")
local vlog = require("plugin_template._vendors.vlog")

local M = {}

--- Count a sheep for each `count`.
---
---@param count number Prints 1 sheep per `count`. A value that is 1-or-greater.
---
function M.run(count)
    configuration.initialize_data_if_needed()
    vlog.debug("Running goodnight-moon count-sheep")

    if count < 1 then
        vlog.fmt_warn('Count "%s" cannot be less than 1. Using 1 instead.', count)

        count = 1
    end

    for index = 1, count do
        vim.notify(string.format("%s Sheep", index), vim.log.levels.INFO)
    end
end

return M
