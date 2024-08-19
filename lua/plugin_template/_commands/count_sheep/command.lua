--- The main file that implements `goodnight-moon count-sheep` outside of COMMAND mode.
---
--- @module 'plugin_template._commands.count_sheep.command'
---

local M = {}

--- Count a sheep for each `count`.
---
--- @param count number Prints 1 sheep per `count`. A value that is 1-or-greater.
---
function M.run(count)
    if count < 1 then
        -- TODO: Log warning
        count = 1
    end

    -- TODO: Finish
end

return M
