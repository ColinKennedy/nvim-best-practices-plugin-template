--- The main parser for the `:PluginTemplate copy-logs` command.
---
---@module 'plugin_template._commands.copy_logs.parser'
---

local argparse2 = require("plugin_template._cli.argparse2")

local M = {}

---@return argparse2.ParameterParser # The main parser for the `:PluginTemplate copy-logs` command.
function M.make_parser()
    local parser = argparse2.ParameterParser.new({ "copy-logs", help = "Get debug logs for PluginTemplate." })

    -- TODO: Make sure this argument works
    parser:add_parameter({
        "log",
        required = false,
        default = "",
        help = "The path on-disk to look for logs. If no path is given, a fallback log path is used instead.",
    })

    parser:set_execute(function(data)
        local runner = require("plugin_template._commands.copy_logs.runner")

        runner.run(data.namespace.log)
    end)

    return parser
end

return M
