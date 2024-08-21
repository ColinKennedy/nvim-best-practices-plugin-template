--- All `plugin_template` command definitions.

--- @class PluginTemplateSubcommand
---     A Python subparser's definition.
--- @field run fun(data: string[], options: table?): nil
---     The function to run when the subcommand is called.
--- @field complete? fun(data: string): string[]
---     Command completions callback, the `data` are  the lead of the subcommand's arguments

local cli_subcommand = require("plugin_template._cli.cli_subcommand")

local _PREFIX = "PluginTemplate"

--- @alias PluginTemplateSubcommands table<string, PluginTemplateSubcommand>

--- @type PluginTemplateSubcommands
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
        run = function(arguments)
            local runner = require("plugin_template._cli.runner")

            runner.run_goodnight_moon(arguments)
        end,
    },
    ["hello-world"] = {
        complete = function(data)
            local argparse = require("plugin_template._cli.argparse")
            local completion = require("plugin_template._cli.completion")
            -- TODO: include say/constant.lua later

            local tree = {
                "say",
                { "phrase", "word" },
                {
                    {
                        choices = function(value)
                            if value == "" then
                                value = 0
                            else
                                value = tonumber(value)

                                if type(value) ~= "number" then
                                    return {}
                                end
                            end

                            --- @cast value number

                            local output = {}

                            for index = 1, 5 do
                                table.insert(output, tostring(value + index))
                            end

                            return output
                        end,
                        name = "repeat",
                        argument_type = argparse.ArgumentType.named,
                    },
                    {
                        argument_type = argparse.ArgumentType.named,
                        name = "style",
                        choices = { "lowercase", "uppercase" },
                    },
                },
            }

            local arguments = argparse.parse_arguments(data)

            return completion.get_options(tree, arguments, vim.fn.getcmdpos())
        end,
        run = function(arguments)
            local runner = require("plugin_template._cli.runner")

            runner.run_hello_world(arguments)
        end,
    },
}

vim.api.nvim_create_user_command(_PREFIX, cli_subcommand.make_triager(_SUBCOMMANDS), {
    nargs = "+",
    desc = "PluginTemplate's command API.",
    complete = cli_subcommand.make_command_completer(_PREFIX, _SUBCOMMANDS),
})

-- TODO: Make sure <Plug> works
vim.keymap.set("n", "<Plug>(PluginTemplateSayHi)", function()
    local plugin_template = require("plugin_template.api")

    plugin_template.run_hello_world("Hi!")
end, { desc = "Say hi to the user." })
