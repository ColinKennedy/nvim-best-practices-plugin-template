--- Parse `"goodnight-moon read"` from COMMAND mode and run it.
---
--- @module 'plugin_template._commands.count_sheep.cli'
---

local read_command = require("plugin_template._commands.goodnight_moon.read.command")

local M = {}

--- Parse `"goodnight-moon read"` from COMMAND mode and run it.
---
--- @param data ArgparseResults All found user data.
---
function M.run(data)
    local book = data.arguments[1].value
    read_command.run(book)
end

return M
