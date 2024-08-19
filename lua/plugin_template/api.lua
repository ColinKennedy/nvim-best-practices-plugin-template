--- All function(s) that can be called externally by other Lua modules.
---
--- If a function's signature here changes in some incompatible way, this
--- package must get a new *major* version.
---
--- @module 'plugin_template.api'
---

local count_sheep_command = require("plugin_template._commands.count_sheep.command")
local read_command = require("plugin_template._commands.read.command")
local say_command = require("plugin_template._commands.say.command")
local sleep_command = require("plugin_template._commands.sleep.command")

local M = {}

-- TODO: Make sure type-hinting works with this
M.run_hello_world_say_phrase = say_command.run_say_phrase
M.run_hello_world_say_word = say_command.run_say_word
M.run_goodnight_moon_read = read_command.run
M.run_goodnight_moon_count_sheep = count_sheep_command.run
M.run_goodnight_moon_sleep = sleep_command.run

return M
