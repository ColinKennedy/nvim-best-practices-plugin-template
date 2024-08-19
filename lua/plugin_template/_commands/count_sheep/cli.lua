--- Parse `"goodnight-moon count-sheep"` from COMMAND mode and run it.
---
--- @module 'plugin_template._commands.count_sheep.cli'
---

local count_sheep_command = require("plugin_template._commands.count_sheep.command")

local M = {}

--- Parse `"goodnight-moon count-sheep"` from COMMAND mode and run it.
---
--- @param data ArgparseResults All found user data.
---
function M.run(data)
    local value = data.arguments[1].value
    --- @cast value string
    local count = tonumber(value) or 1

    count_sheep_command.run(count)
end

return M
