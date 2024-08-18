--- All `plugin_name` command definitions.

--- @class PluginNameSubcommand
---     A Python subparser's definition.
--- @field run fun(data: string[], options: table?): nil
---     The function to run when the subcommand is called.
--- @field complete? fun(data: string): string[]
---     Command completions callback, the `data` are  the lead of the subcommand's arguments

local cli_subcommand = require("plugin_name._cli.cli_subcommand")

local _PREFIX = "PluginName"

--- @alias PluginNameSubcommands table<string, PluginNameSubcommand>

--- @type PluginNameSubcommands
local _SUBCOMMANDS = {
    ["goodnight-moon"] = {
        complete = function(data)
            -- TODO: Add support later
            return nil
            -- local positional_choices = {
            --     [1] = { "count-sheep", "read", "sleep" },
            -- }
            --
            -- return cli_subcommand.get_complete_options(data, positional_choices)
        end,
        run = function(data)
            local runner = require("plugin_name._cli.runner")

            runner.run_goodnight_moon(data)
        end,
    },
    ["hello-world"] = {
        complete = function(data)
            -- TODO: Add support later
            return nil
            -- local argparse = require("plugin_name._cli.argparse")
            -- local completion = require("plugin_name._cli.completion")
            -- TODO: include say/constant.lua later
            --
            -- local tree = {
            --     "say",
            --     {"phrase", "word"},
            --     {
            --         {
            --             choices=function(value)
            --                 local output = {}
            --                 value = value or 0
            --
            --                 for index=1,10 do
            --                     table.insert(output, value + index)
            --                 end
            --
            --                 return output
            --             end,
            --             name="repeat",
            --             type=completion.NamedArgument,
            --         },
            --         {type=completion.NamedArgument, name="style", choices={"lowercase", "uppercase"}},
            --     }
            -- }
            --
            -- local arguments = argparse.parse_args(data)
            --
            -- return completion.get_options(tree, arguments)
        end,
        run = function(_, options)
            local runner = require("plugin_name._cli.runner")

            runner.run_hello_world(options.args)
        end,
    },
}

vim.api.nvim_create_user_command(_PREFIX, cli_subcommand.make_triager(_SUBCOMMANDS), {
    nargs = "+",
    desc = "PluginName's command API.",
    complete = cli_subcommand.make_command_completer(_PREFIX, _SUBCOMMANDS),
})

vim.keymap.set("n", "<Plug>(PluginNameSayHi)", function()
    local plugin_name = require("plugin_name.api")

    plugin_name.run_hello_world("Hi!")
end, { desc = "Say hi to the user." })
