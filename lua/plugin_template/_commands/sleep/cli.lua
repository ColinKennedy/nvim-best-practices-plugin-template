--- Parse `"goodnight-moon sleep"` from COMMAND mode and run it.
---
--- @module 'plugin_template._commands.sleep.cli'
---

local argparse = require("plugin_template._cli.argparse")
local sleep_command = require("plugin_template._commands.sleep.command")

local M = {}

local function _is_z_flag(argument)
    return argument.argument_type == argparse.ArgumentType.flag and argument.name == "z"
end

--- Parse `"goodnight-moon sleep"` from COMMAND mode and run it.
---
--- @param data ArgparseResults All found user data.
---
function M.run(data)
    local count = 0

    for _, argument in ipairs(data.arguments) do
        if _is_z_flag(argument) then
            count = count + 1
        end
    end

    sleep_command.run(count)
end

return M
