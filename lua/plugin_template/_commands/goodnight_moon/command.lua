--- Parse `"goodnight-moon sleep"` from the COMMAND mode and run it.
---
--- @module 'plugin_template._commands.goodnight_moon.sleep.command'
---

-- TODO: Docstring

local count_sheep = require("plugin_template._commands.goodnight_moon.count_sheep")
local read = require("plugin_template._commands.goodnight_moon.read")
local sleep = require("plugin_template._commands.goodnight_moon.sleep")


local M = {}


function M.run_count_sheep(namespace)
    count_sheep.run(namespace.count)
end


function M.run_read(namespace)
    read.run(namespace.book)
end


function M.run_sleep(namespace)
    sleep.run(namespace.count)
end

return M
