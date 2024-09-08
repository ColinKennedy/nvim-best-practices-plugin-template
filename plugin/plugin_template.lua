--- All `plugin_template` command definitions.

local cli_subcommand = require("plugin_template._cli.cli_subcommand")

local _PREFIX = "PluginTemplate"

---@type plugin_template.Subcommands
local _SUBCOMMANDS = {
    ["arbitrary-thing"] = function()
        local parser = require("plugin_template._commands.arbitrary_thing.parser")

        return parser.make_parser()
    end,
    ["copy-logs"] = function()
        local parser = require("plugin_template._commands.copy_logs.parser")

        return parser.make_parser()
    end,
    ["goodnight-moon"] = function()
        local parser = require("plugin_template._commands.goodnight_moon.parser")

        return parser.make_parser()
    end,
    ["hello-world"] = function()
        local parser = require("plugin_template._commands.hello_world.parser")

        return parser.make_parser()
    end,
}

cli_subcommand.initialize_missing_values(_SUBCOMMANDS)

vim.api.nvim_create_user_command(_PREFIX, cli_subcommand.make_triager(_SUBCOMMANDS), {
    nargs = "+",
    desc = "PluginTemplate's command API.",
    complete = cli_subcommand.make_command_completer(_PREFIX, _SUBCOMMANDS),
})

vim.keymap.set("n", "<Plug>(PluginTemplateSayHi)", function()
    local configuration = require("plugin_template._core.configuration")
    local plugin_template = require("plugin_template")

    configuration.initialize_data_if_needed()

    plugin_template.run_hello_world_say_word("Hi!")
end, { desc = "Say hi to the user." })
