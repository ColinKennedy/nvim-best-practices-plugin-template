--- Parse `"hello-world say"` from COMMAND mode and run it.
---
--- @module 'plugin_name._commands.say.cli'
---

local constant = require("plugin_name._commands.say.constant")
local say_command = require("plugin_name._commands.say.command")

local M = {}

--- Parse `"hello-world say"` from COMMAND mode and run it.
---
--- @param data ArgparseResults All found user data.
---
function M.run_say(data)
    local subcommand = data.arguments[1].value

    if subcommand == constant.Subcommand.phrase then
        say_command.run_say_phrase(data)

        return
    end

    if subcommand == constant.Subcommand.word then
        say_command.run_say_word(data.arguments[1].value)

        return
    end

    vim.notify(
        string.format(
            'say command failed. Got "%s", expected "%s" subcommand.',
            subcommand,
            vim.inspect({constant.Subcommand.phrase, constant.Subcommand.word})
        ),
        vim.log.levels.ERROR
    )
end

return M
