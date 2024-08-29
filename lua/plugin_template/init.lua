--- All function(s) that can be called externally by other Lua modules.
---
--- If a function's signature here changes in some incompatible way, this
--- package must get a new *major* version.
---
--- @module 'plugin_template'
---

local configuration = require("plugin_template._core.configuration")
local copy_logs_runner = require("plugin_template._commands.copy_logs.runner")
local count_sheep_runner = require("plugin_template._commands.goodnight_moon.count_sheep.runner")
local read_runner = require("plugin_template._commands.goodnight_moon.read.runner")
local say_runner = require("plugin_template._commands.hello_world.say.runner")
local sleep_runner = require("plugin_template._commands.goodnight_moon.sleep.runner")

local M = {}

configuration.initialize_data_if_needed()

-- TODO: (you) - Change this file to whatever you need it to be. These are just
-- some example commands
M.run_copy_logs = copy_logs_runner.run
M.run_hello_world_say_phrase = say_runner.run_say_phrase
M.run_hello_world_say_word = say_runner.run_say_word
M.run_goodnight_moon_read = read_runner.run
M.run_goodnight_moon_count_sheep = count_sheep_runner.run
M.run_goodnight_moon_sleep = sleep_runner.run

return M
