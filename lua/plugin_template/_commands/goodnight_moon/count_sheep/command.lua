--- Parse `"goodnight-moon count-sheep"` from the COMMAND mode and run it.
---
--- @module 'plugin_template._commands.goodnight_moon.count_sheep.command'
---

local count_sheep_runner = require("plugin_template._commands.goodnight_moon.count_sheep.runner")

local M = {}

--- Parse `"goodnight-moon count-sheep"` from the COMMAND mode and run it.
---
--- @param data ArgparseResults All found user data.
---
function M.run(data)
    local argument = data.arguments[1]
    local count = 1

    if argument then
        local value = argument.value
        --- @cast value string
        count = tonumber(value) or 1
    end

    count_sheep_runner.run(count)
end

return M
