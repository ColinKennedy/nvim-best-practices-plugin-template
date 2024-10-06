--- All `plugin_template` command definitions.

local cli_subcommand = require("plugin_template._cli.cli_subcommand")

local _PREFIX = "PluginTemplate"

---@type plugin_template.ParserCreator
local _SUBCOMMANDS = function()
    local arbitrary_thing = require("plugin_template._commands.arbitrary_thing.parser")
    local cmdparse = require("plugin_template._cli.cmdparse")
    local copy_logs = require("plugin_template._commands.copy_logs.parser")
    local goodnight_moon = require("plugin_template._commands.goodnight_moon.parser")
    local hello_world = require("plugin_template._commands.hello_world.parser")

    local root_parser = cmdparse.ParameterParser.new({ help = "The root of all commands." })
    local root_subparsers = root_parser:add_subparsers({ "command", help = "All root commands." })

    local parser = root_subparsers:add_parser({ name = _PREFIX, help = "The starting command." })
    local subparsers = parser:add_subparsers({ "commands", help = "All runnable commands." })

    subparsers:add_parser(arbitrary_thing.make_parser())
    subparsers:add_parser(copy_logs.make_parser())
    subparsers:add_parser(goodnight_moon.make_parser())
    subparsers:add_parser(hello_world.make_parser())

    return root_parser
end

vim.api.nvim_create_user_command(_PREFIX, cli_subcommand.make_parser_triager(_SUBCOMMANDS), {
    nargs = "*",
    desc = "PluginTemplate's command API.",
    complete = cli_subcommand.make_parser_completer(_SUBCOMMANDS),
})

vim.keymap.set("n", "<Plug>(PluginTemplateSayHi)", function()
    local configuration = require("plugin_template._core.configuration")
    local plugin_template = require("plugin_template")

    configuration.initialize_data_if_needed()

    plugin_template.run_hello_world_say_word("Hi!")
end, { desc = "Say hi to the user." })
