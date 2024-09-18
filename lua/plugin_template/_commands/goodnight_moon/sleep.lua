--- The main file that implements `goodnight-moon sleep` outside of COMMAND mode.
---
---@module 'plugin_template._commands.goodnight_moon.sleep.runner'
---

local vlog = require("plugin_template._vendors.vlog")

local M = {}

--- Print Zzz each `count`.
---
---@param count number? Prints 1 Zzz per `count`. A value that is 1-or-greater.
---
function M.run(count)
    vlog.debug("Running goodnight-moon count-sheep")

    if count == nil then
        count = 1
    end

    if count < 1 then
        vlog.fmt_warn('count-sheep "%s" is invalid. Setting the value to to 1-or-greater, instead.', count)

        count = 1
    end

    for _ = 1, count do
        vim.notify("Zzz", vim.log.levels.INFO)
    end
end

return M
