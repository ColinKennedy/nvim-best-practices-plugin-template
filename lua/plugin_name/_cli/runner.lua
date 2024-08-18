--- Run Vim commands like `:PluginName` in Lua.
---
--- @module 'plugin_name._cli.runner'
---

local argparse = require("plugin_name._cli.argparse")
local say_command = require("plugin_name._cli.say_command")
local tabler = require("plugin_name._core.tabler")

local _STARTING_COMMANDS = {
    say = say_command.run_say,
}

local M = {}

-- TODO: Docstrings

-- TODO: Add better code here

function M.run_goodnight_moon(data)
    local positions, named = argparse.parse_args(data)
end

function M.run_hello_world(data)
    local positions, named = unpack(argparse.parse_args(data))
    positions = tabler.get_slice(positions, 2)

    local runner = _STARTING_COMMANDS[positions[1]]

    runner({ positions = positions, named = named })
end

return M
