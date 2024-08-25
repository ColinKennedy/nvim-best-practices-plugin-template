--- Parse `"goodnight-moon read"` from COMMAND mode and run it.
---
--- @module 'plugin_template._commands.count_sheep.cli'
---

local read_runner = require("plugin_template._commands.goodnight_moon.read.runner")

local M = {}

--- Parse `"goodnight-moon read"` from COMMAND mode and run it.
---
--- @param data ArgparseResults All found user data.
---
function M.run(data)
    local book = data.arguments[1].value
    read_runner.run(book)
end

return M
