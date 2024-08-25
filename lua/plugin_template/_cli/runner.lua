--- Run Vim commands like `:PluginTemplate` in Lua.
---
--- @module 'plugin_template._cli.command'
---

local argparse_helper = require("plugin_template._cli.argparse_helper")
local count_sheep_command = require("plugin_template._commands.goodnight_moon.count_sheep.command")
local read_command = require("plugin_template._commands.goodnight_moon.read.command")
local say_command = require("plugin_template._commands.hello_world.say.command")
local sleep_command = require("plugin_template._commands.goodnight_moon.sleep.command")
local vlog = require("plugin_template._vendors.vlog")

local _STARTING_GOODNIGHT_MOON_COMMANDS = {
    ["count-sheep"] = count_sheep_command.run,
    read = read_command.run,
    sleep = sleep_command.run,
}
local _STARTING_HELLO_WORLD_COMMANDS = { say = say_command.run_say }

local M = {}

--- Copy the contents of the saved log file to the user's system clipboard.
function M.run_copy_logs()
    local path = vlog:get_log_path()

    if not path or vim.fn.filereadable(path) ~= 1 then
        vim.notify(
            string.format('No "%s" path. Cannot copy the logs.', path),
            vim.log.levels.ERROR
        )

        return
    end

    local file = io.open(path, "r")

    if not file then
      vim.notify(
          string.format('Failed to read "%s" path. Cannot copy the logs.', path),
          vim.log.levels.ERROR
      )

      return
    end

    local contents = file:read("*a")

    file:close()

    vim.fn.setreg("+", contents)

    vim.notify(
        string.format('Log file "%s" was copied to the clipboard.', path),
        vim.log.levels.INFO
    )
end

--- Run one of the `goodnight-moon {read,sleep,...}` commands using `data`.
---
--- @param data ArgparseResults
---     The parsed user input. e.g. `'goodnight-moon read "a book"'`.
---
function M.run_goodnight_moon(data)
    local command = _STARTING_GOODNIGHT_MOON_COMMANDS[data.arguments[2].value]
    data = argparse_helper.lstrip_arguments(data, 3)

    command(data)
end

--- Run one of the `hello-world {say} {phrase,word}` commands using `data`.
---
--- @param data ArgparseResults
---     The parsed user input. e.g. `'goodnight-moon read "a book"'`.
---
function M.run_hello_world(data)
    local command = _STARTING_HELLO_WORLD_COMMANDS[data.arguments[2].value]
    data = argparse_helper.lstrip_arguments(data, 3)

    command(data)
end

return M
