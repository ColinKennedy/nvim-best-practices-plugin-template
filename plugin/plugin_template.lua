--- All `plugin_template` command definitions.

local cmdparse = require("mega.cmdparse")

local _PREFIX = "PluginTemplate"

---@type mega.cmdparse.ParserCreator
local _SUBCOMMANDS = function()
    local arbitrary_thing = require("plugin_template._commands.arbitrary_thing.parser")
    local copy_logs = require("plugin_template._commands.copy_logs.parser")
    local goodnight_moon = require("plugin_template._commands.goodnight_moon.parser")
    local hello_world = require("plugin_template._commands.hello_world.parser")

    local parser = cmdparse.ParameterParser.new({ name = _PREFIX, help = "The root of all commands." })
    local subparsers = parser:add_subparsers({ "commands", help = "All runnable commands." })

    subparsers:add_parser(arbitrary_thing.make_parser())
    subparsers:add_parser(copy_logs.make_parser())
    subparsers:add_parser(goodnight_moon.make_parser())
    subparsers:add_parser(hello_world.make_parser())

    return parser
end

cmdparse.create_user_command(_SUBCOMMANDS, _PREFIX)

vim.keymap.set("n", "<Plug>(PluginTemplateSayHi)", function()
    local configuration = require("plugin_template._core.configuration")
    local plugin_template = require("plugin_template")

    configuration.initialize_data_if_needed()

    plugin_template.run_hello_world_say_word("Hi!")
end, { desc = "Say hi to the user." })
