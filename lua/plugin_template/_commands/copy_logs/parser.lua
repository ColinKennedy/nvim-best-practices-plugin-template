-- TODO: Docstring

local argparse2 = require("plugin_template._cli.argparse2")

local M = {}

function M.make_parser()
    local parser = argparse2.ArgumentParser.new({"copy-logs", description="Get debug logs for PluginTemplate."})

    -- TODO: Make sure this argument works
    parser:add_argument({
        "log",
        required=false,
        description="The path on-disk to look for logs. "
        .. "If no path is given, a fallback log path is used instead.",
    })

    parser:set_execute(
        function(data)
            local command = require("plugin_template._commands.copy_log.command")

            command.run(data.namespace)
        end
    )

    return parser
end

return M
