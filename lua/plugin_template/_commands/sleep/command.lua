--- The main file that implements `goodnight-moon sleep` outside of COMMAND mode.
---
--- @module 'plugin_template._commands.sleep.command'
---

local M = {}

M._print = print

--- Print zzz each `count`.
---
--- @param count number Prints 1 zzz per `count`. A value that is 1-or-greater.
---
function M.run(count)
    if count < 1 then
        -- TODO: Log warning
        count = 1
    end

    for _=1,count do
        M._print("zzz")
    end
end

return M
