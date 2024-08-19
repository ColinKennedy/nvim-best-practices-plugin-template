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
--- @param data string Raw user input. e.g. `'goodnight-moon read "a book"'`.
---
function M.run_goodnight_moon(data)
    local results = argparse.parse_arguments(data)
    local runner = _STARTING_GOODNIGHT_MOON_COMMANDS[results.arguments[2].value]
    results = argparse_helper.lstrip_arguments(results, 2)

    runner(results)
end

--- Run one of the `hello-world {say} {phrase,word}` commands using `data`.
---
--- @param data string Raw user input. e.g. `'hello-world say phrase "Hello, World!"'`.
---
function M.run_hello_world(data)
    local results = argparse.parse_arguments(data)
    local runner = _STARTING_HELLO_WORLD_COMMANDS[results.arguments[2].value]
    results = argparse_helper.lstrip_arguments(results, 3)

    runner(results)
end

return M