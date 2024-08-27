--- The main file that implements `goodnight-moon sleep` outside of COMMAND mode.
---
--- @module 'plugin_template._commands.sleep.command'
---

local state = require("plugin_template._core.state")
local vlog = require("plugin_template._vendors.vlog")

local M = {}


--- Print zzz each `count`.
---
--- @param count number? Prints 1 zzz per `count`. A value that is 1-or-greater.
---
function M.run(count)
    vlog.debug("Running goodnight-moon count-sheep")

    if count == nil then
        count = 1
    end

    state.PREVIOUS_COMMAND = "goodnight_moon"

    if count < 1 then
        vlog.fmt_warn('count-sheep "%s" is invalid. Setting the value to to 1-or-greater, instead.', count)

        count = 1
    end

    for _ = 1, count do
        vim.notify("zzz", vim.log.levels.INFO)
    end
end

return M
