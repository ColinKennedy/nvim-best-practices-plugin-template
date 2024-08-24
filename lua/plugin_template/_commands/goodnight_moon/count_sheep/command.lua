--- The main file that implements `goodnight-moon count-sheep` outside of COMMAND mode.
---
--- @module 'plugin_template._commands.count_sheep.command'
---

local state = require("plugin_template._core.state")

local M = {}

M._print = print

--- Count a sheep for each `count`.
---
--- @param count number Prints 1 sheep per `count`. A value that is 1-or-greater.
---
function M.run(count)
    state.PREVIOUS_COMMAND = "goodnight_moon"

    if count < 1 then
        -- TODO: Log warning
        count = 1
    end

    for index = 1, count do
        M._print(string.format("%s Sheep", index))
    end
end

return M
