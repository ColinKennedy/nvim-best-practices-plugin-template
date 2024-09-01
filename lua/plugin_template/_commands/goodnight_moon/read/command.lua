--- Parse `"goodnight-moon read"` from the COMMAND mode and run it.
---
--- @module 'plugin_template._commands.goodnight_moon.read.command'
---

local read_runner = require("plugin_template._commands.goodnight_moon.read.runner")

local M = {}

--- Parse `"goodnight-moon read"` from the COMMAND mode and run it.
---
--- @param data ArgparseResults All found user data.
---
function M.run(data)
    local book = data.arguments[1].value
    --- @cast book string
    read_runner.run(book)
end

return M
