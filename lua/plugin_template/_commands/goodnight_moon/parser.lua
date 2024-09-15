-- TODO: Docstring

local argparse2 = require("plugin_template._cli.argparse2")

local M = {}


function M.make_parser()
    local parser = argparse2.ArgumentParser.new({"goodnight-moon", description="Prepare to sleep or sleep."})
    local subparsers = parser:add_subparsers({destination="commands", description="All commands for goodnight-moon."})
    subparsers.required = true

    -- TODO: Finish this stuff later
    local count_sheep = subparsers:add_parser({"count-sheep", description="Count some sheep to help you sleep."})
    count_sheep:add_argument({"count", type="number", description="The number of sheept to count."})
    local read = subparsers:add_parser({"read", description="Read a book in bed."})
    read:add_argument({"book", description="The name of the book to read."})

    local sleep = subparsers:add_parser({"sleep", description="Sleep tight!"})
    sleep:add_argument({
        "-z",
        action="count",
        count="*",
        description="The number of Zzz to print.",
        destination="count",
    })

    count_sheep:set_execute(
        function(namespace)
            local command = require("plugin_template._commands.goodnight_moon.command")

            command.run_count_sheep(namespace)
        end
    )

    read:set_execute(
        function(namespace)
            local command = require("plugin_template._commands.goodnight_moon.command")

            command.run_read(namespace)
        end
    )

    sleep:set_execute(
        function(namespace)
            local command = require("plugin_template._commands.goodnight_moon.command")

            command.run_sleep(namespace)
        end
    )

    return parser
end

return M
