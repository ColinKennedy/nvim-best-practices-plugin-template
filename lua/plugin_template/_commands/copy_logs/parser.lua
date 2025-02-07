--- The main parser for the `:PluginTemplate copy-logs` command.

local cmdparse = require("mega.cmdparse")

local M = {}

---@return mega.cmdparse.ParameterParser # The main parser for the `:PluginTemplate copy-logs` command.
function M.make_parser()
    local parser = cmdparse.ParameterParser.new({ "copy-logs", help = "Get debug logs for PluginTemplate." })

    parser:add_parameter({
        "log",
        required = false,
        help = "The path on-disk to look for logs. If no path is given, a fallback log path is used instead.",
    })

    parser:set_execute(function(data)
        ---@cast data mega.cmdparse.NamespaceExecuteArguments
        local runner = require("plugin_template._commands.copy_logs.runner")

        runner.run(data.namespace.log)
    end)

    return parser
end

return M
