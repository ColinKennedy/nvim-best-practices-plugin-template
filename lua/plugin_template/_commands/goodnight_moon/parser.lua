-- TODO: Docstring

local argparse2 = require("plugin_template._cli.argparse2")

local M = {}

function M.make_parser()
    local parser = argparse2.ParameterParser.new({ "goodnight-moon", help = "Prepare to sleep or sleep." })
    local subparsers = parser:add_subparsers({ destination = "commands", help = "All commands for goodnight-moon." })
    subparsers.required = true

    -- TODO: Finish this stuff later
    local count_sheep = subparsers:add_parser({ "count-sheep", help = "Count some sheep to help you sleep." })
    count_sheep:add_parameter({ "count", type = "number", help = "The number of sheept to count." })
    local read = subparsers:add_parser({ "read", help = "Read a book in bed." })
    read:add_parameter({ "book", help = "The name of the book to read." })

    local sleep = subparsers:add_parser({ "sleep", help = "Sleep tight!" })
    sleep:add_parameter({
        "-z",
        action = "count",
        count = "*",
        destination = "count",
        help = "The number of Zzz to print.",
    })

    count_sheep:set_execute(function(data)
        local count_sheep_ = require("plugin_template._commands.goodnight_moon.count_sheep")

        count_sheep_.run(data.namespace.count)
    end)

    read:set_execute(function(data)
        local read_ = require("plugin_template._commands.goodnight_moon.read")

        read_.run(data.namespace.book)
    end)

    sleep:set_execute(
        -- TODO: Make sure to add type-hints for all of these inner functions (across all files)
        function(data)
            local sleep_ = require("plugin_template._commands.goodnight_moon.sleep")

            sleep_.run(data.namespace.count)
        end
    )

    return parser
end

return M
