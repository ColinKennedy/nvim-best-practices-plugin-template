-- TODO: Docstring

local argparse2 = require("plugin_template._cli.argparse2")

local M = {}

function M.make_parser()
    local parser = argparse2.ArgumentParser.new({ "goodnight-moon", description = "Prepare to sleep or sleep." })
    local subparsers =
        parser:add_subparsers({ destination = "commands", description = "All commands for goodnight-moon." })
    subparsers.required = true

    -- TODO: Finish this stuff later
    local count_sheep = subparsers:add_parser({ "count-sheep", description = "Count some sheep to help you sleep." })
    count_sheep:add_argument({ "count", type = "number", description = "The number of sheept to count." })
    local read = subparsers:add_parser({ "read", description = "Read a book in bed." })
    read:add_argument({ "book", description = "The name of the book to read." })

    local sleep = subparsers:add_parser({ "sleep", description = "Sleep tight!" })
    sleep:add_argument({
        "-z",
        action = "count",
        count = "*",
        description = "The number of Zzz to print.",
        destination = "count",
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
