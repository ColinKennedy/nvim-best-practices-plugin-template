--- Run Vim commands like `:PluginTemplate` in Lua.
---
--- @module 'plugin_template._cli.command'
---

local argparse_helper = require("plugin_template._cli.argparse_helper")
local copy_logs_command = require("plugin_template._commands.copy_logs.command")
local count_sheep_command = require("plugin_template._commands.goodnight_moon.count_sheep.command")
local read_command = require("plugin_template._commands.goodnight_moon.read.command")
local say_command = require("plugin_template._commands.hello_world.say.command")
local sleep_command = require("plugin_template._commands.goodnight_moon.sleep.command")

local _STARTING_GOODNIGHT_MOON_COMMANDS = {
    ["count-sheep"] = count_sheep_command.run,
    read = read_command.run,
    sleep = sleep_command.run,
}
local _STARTING_HELLO_WORLD_COMMANDS = { say = say_command.run_say }

local M = {}

--- Copy the contents of the saved log file to the user's system clipboard.
function M.run_copy_logs(data)
    local log_path = data.arguments[2]

    copy_logs_command.run(log_path)
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
