--- All `plugin_name` command definitions.

--- @class NeovimCommandAttributes
---     The options that Neovim sends to functions
---     `:help nvim_create_user_command()`
--- @field fargs string[]
---     All space-separated arguments that the user sent when they called the command.

--- @class PluginNameSubcommand
---     A Python subparser's definition.
--- @field run fun(data:string[], opts: table?)
---     The function to run when the subcommand is called.
--- @field complete? fun(data: string): string[]
---     Command completions callback, the `data` are  the lead of the subcommand's arguments

local cli_helper = require("plugin_name._cli.cli_helper")

local _PREFIX = "PluginName"

--- @type table<string, PluginNameSubcommand>
local _SUBCOMMANDS = {
  -- TODO: Add a second sub-command, for fun
  ["hello-world"] = {
    complete = function(data)
      local positional_choices = {
        [1] = {"say"},
        [2] = {"phrase", "word"},
      }

      local named_choices = {
        ["repeat"] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
        style = {"undercase", "uppercase"},
      }

      return cli_helper.get_complete_options(data, positional_choices, named_choices)
    end,
    run = function(data)
      local runner = require("plugin_name._cli.runner")

      runner.run_hello_world(data)
    end,
  }
}

vim.api.nvim_create_user_command(_PREFIX, cli_helper.make_triager(_SUBCOMMANDS), {
  nargs = "+",
  desc = "PluginName's command API.",
  complete = cli_helper.make_command_completer(_PREFIX, _SUBCOMMANDS)
})

-- TODO: Finish these
-- vim.keymap.set("n", "<Plug>(SpellboundGoToPreviousRecommendation)", function()
--   require("plugin_name").go_to_previous_recommendation()
-- end, { desc = "Go to the previous recommendation." })
--
-- vim.keymap.set("n", "<Plug>(SpellboundGoToNextRecommendation)", function()
--   require("spellbound").go_to_next_recommendation()
-- end, { desc = "Go to the next recommendation." })
--
--
-- vim.api.nvim_create_user_command("MyFirstFunction", require("plugin_name").hello, {})
