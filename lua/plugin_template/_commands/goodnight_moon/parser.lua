--- The main parser for the `:PluginTemplate goodnight-moon` command.
---
---@module 'plugin_template._commands.goodnight_moon.parser'
---

local cmdparse = require("plugin_template._cli.cmdparse")

local M = {}

---@return cmdparse.ParameterParser # The main parser for the `:PluginTemplate goodnight-moon` command.
function M.make_parser()
    local parser = cmdparse.ParameterParser.new({ "goodnight-moon", help = "Prepare to sleep or sleep." })
    local subparsers =
        parser:add_subparsers({ destination = "commands", help = "All goodnight-moon commands.", required = true })

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
        ---@cast data plugin_template.NamespaceExecuteArguments
        local count_sheep_ = require("plugin_template._commands.goodnight_moon.count_sheep")

        count_sheep_.run(data.namespace.count)
    end)

    read:set_execute(function(data)
        ---@cast data plugin_template.NamespaceExecuteArguments
        local read_ = require("plugin_template._commands.goodnight_moon.read")

        read_.run(data.namespace.book)
    end)

    sleep:set_execute(function(data)
        ---@cast data plugin_template.NamespaceExecuteArguments
        local sleep_ = require("plugin_template._commands.goodnight_moon.sleep")

        sleep_.run(data.namespace.count)
    end)

    return parser
end

return M
