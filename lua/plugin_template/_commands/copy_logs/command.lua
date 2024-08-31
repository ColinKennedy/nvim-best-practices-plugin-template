--- Parse `"copy-logs"` from the COMMAND mode and run it.
---
--- @module 'plugin_template._commands.copy_logs.command'
---

local argparse = require("plugin_template._cli.argparse")
local copy_logs_runner = require("plugin_template._commands.copy_logs.runner")

local M = {}

--- If the user provided a file path to read from, find and return it.
---
--- @param arguments ArgparseResults All given user arguments.
---
local function _get_log_path(arguments)
    for _, argument in ipairs(arguments) do
        if argument.argument_type == argparse.ArgumentType.position then
            if argument.value ~= "" then
                return argument.value
            end
        end
    end

    return nil
end

--- Parse `"copy-logs"` from the COMMAND mode and run it.
---
--- @param data ArgparseResults All found user data.
---     A path on-disk to look for logs. If none is given, the default fallback
---     location is used instead.
---
function M.run(data)
    local path = _get_log_path(data.arguments)

    copy_logs_runner.run(path)
end

return M
