--- All `plugin_template` command definitions.

local cli_subcommand = require("plugin_template._cli.cli_subcommand")

local _PREFIX = "PluginTemplate"

--- @type PluginTemplateSubcommands
local _SUBCOMMANDS = {
    ["copy-logs"] = {
        run = function(arguments)
            local runner = require("plugin_template._cli.runner")

            runner.run_copy_logs(arguments)
        end,
    },
    ["goodnight-moon"] = {
        complete = function(data)
            local argparse = require("plugin_template._cli.argparse")
            local completion = require("plugin_template._cli.completion")

            local tree = { ["count-sheep"] = {}, ["read"] = {}, ["sleep"] = {} }
            local arguments = argparse.parse_arguments(data)

            return completion.get_options(tree, arguments, vim.fn.getcmdpos())
        end,
        run = function(arguments)
            local runner = require("plugin_template._cli.runner")

            runner.run_goodnight_moon(arguments)
        end,
    },
    ["hello-world"] = {
        complete = function(data)
            local complete = require("plugin_template._commands.hello_world.complete")

            return complete.complete(data)
        end,
        run = function(arguments)
            local runner = require("plugin_template._cli.runner")

            runner.run_hello_world(arguments)
        end,
    },
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
