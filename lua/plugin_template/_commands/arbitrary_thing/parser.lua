-- TODO: Docstring

local argparse2 = require("plugin_template._cli.argparse2")

local M = {}

function M.make_parser()
    local parser = argparse2.ParameterParser.new({ "arbitrary-thing", help = "Prepare to sleep or sleep." })

    parser:add_parameter({ "-a" })
    parser:add_parameter({ "-b" })
    parser:add_parameter({ "-c" })
    parser:add_parameter({ "-v", count = "*", destination = "verbose" })
    parser:add_parameter({ "-f", count = "*" })

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
