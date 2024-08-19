--- Run Vim commands like `:PluginTemplate` in Lua.
---
--- @module 'plugin_template._cli.runner'
---

local argparse = require("plugin_template._cli.argparse")
local argparse_helper = require("plugin_template._cli.argparse_helper")
local count_sheep_cli = require("plugin_template._commands.count_sheep.cli")
local read_cli = require("plugin_template._commands.read.cli")
local say_cli = require("plugin_template._commands.say.cli")
local sleep_cli = require("plugin_template._commands.sleep.cli")

local _STARTING_GOODNIGHT_MOON_COMMANDS = {
    ["count-sheep"] = count_sheep_cli.run,
    read = read_cli.run,
    sleep = sleep_cli.run,
}
local _STARTING_HELLO_WORLD_COMMANDS = { say = say_cli.run_say }

local M = {}

--- Run one of the `goodnight-moon {read,sleep,...}` commands using `data`.
---
--- @param data ArgparseResults
---     The parsed user input. e.g. `'goodnight-moon read "a book"'`.
---
function M.run_goodnight_moon(data)
    local runner = _STARTING_GOODNIGHT_MOON_COMMANDS[data.arguments[2].value]
    data = argparse_helper.lstrip_arguments(data, 3)

    runner(data)
end

--- Run one of the `hello-world {say} {phrase,word}` commands using `data`.
---
--- @param data ArgparseResults
---     The parsed user input. e.g. `'goodnight-moon read "a book"'`.
---
function M.run_hello_world(data)
    local runner = _STARTING_HELLO_WORLD_COMMANDS[data.arguments[2].value]
    data = argparse_helper.lstrip_arguments(data, 3)

    runner(data)
end

return M
