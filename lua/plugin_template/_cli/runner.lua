--- Run Vim commands like `:PluginTemplate` in Lua.
---
--- @module 'plugin_template._cli.runner'
---

local argparse = require("plugin_template._cli.argparse")
local argparse_helper = require("plugin_template._cli.argparse_helper")
local say_cli = require("plugin_template._commands.say.cli")

local _STARTING_COMMANDS = {say = say_cli.run_say}

local M = {}

--- Run one of the `goodnight-moon {read,sleep,...}` commands using `data`.
---
--- @param data string Raw user input. e.g. `'goodnight-moon read "a book"'`.
---
function M.run_goodnight_moon(data)
    local results = argparse.parse_arguments(data)
    results = argparse_helper.lstrip_arguments(results, 2)
    -- TODO: Finish this
end

--- Run one of the `hello-world {say} {phrase,word}` commands using `data`.
---
--- @param data string Raw user input. e.g. `'hello-world say phrase "Hello, World!"'`.
---
function M.run_hello_world(data)
    local results = argparse.parse_arguments(data)
    local runner = _STARTING_COMMANDS[results.arguments[2].value]
    results = argparse_helper.lstrip_arguments(results, 3)

    runner(results)
end

return M
