--- The main parser for the `:PluginTemplate arbitrary-thing` command.
---
---@module 'plugin_template._commands.arbitrary_thing.parser'
---

local argparse2 = require("plugin_template._cli.argparse2")

local M = {}

---@return argparse2.ParameterParser # The main parser for the `:PluginTemplate arbitrary-thing` command.
function M.make_parser()
    local parser = argparse2.ParameterParser.new({ "arbitrary-thing", help = "Prepare to sleep or sleep." })

    parser:add_parameter({ "-a", action="store_true" })
    parser:add_parameter({ "-b", action="store_true" })
    parser:add_parameter({ "-c", action="store_true" })
    parser:add_parameter({ "-v", action="store_true", count = "*", destination = "verbose" })
    parser:add_parameter({ "-f", action="store_true", count = "*" })

    parser:set_execute(function(data)
        local runner = require("plugin_template._commands.arbitrary_thing.runner")

        local names = {}

        for _, argument in ipairs(data.input.arguments) do
            table.insert(names, argument.name)
        end

        runner.run(names)
    end)

    return parser
end

return M
