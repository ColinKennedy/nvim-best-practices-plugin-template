-- TODO: Docstring

local argparse2 = require("plugin_template._cli.argparse2")

local M = {}


function M.make_parser()
    local parser = argparse2.ArgumentParser.new({"goodnight-moon", description="Prepare to sleep or sleep."})
    local subparsers = parser:add_subparsers({destination="commands", description="All commands for goodnight-moon."})
    subparsers.required = true

    -- TODO: Finish this stuff later
    local count_sheep = subparsers:add_parser({"count-sheep", description="Count some sheep to help you sleep."})
    local read = subparsers:add_parser({"read", description="Read a book in bed."})
    local sleep = subparsers:add_parser({"sleep", description="Sleep tight!"})

    count_sheep:set_execute(
        function(data)
            local command = require("plugin_template._commands.goodnight_moon.command")

            command.run_count_sheep(data.namespace)
        end
    )

    read:set_execute(
        function(data)
            local command = require("plugin_template._commands.goodnight_moon.command")

            command.run_read(data.namespace)
        end
    )

    sleep:set_execute(
        function(data)
            local command = require("plugin_template._commands.goodnight_moon.command")

            command.run_sleep(data.namespace)
        end
    )

    return parser
end

return M
