--- All function(s) that can be called externally by other Lua modules.
---
--- If a function's signature here changes in some incompatible way, this
--- package must get a new *major* version.
---
--- @module 'plugin_template'
---

local configuration = require("plugin_template._core.configuration")
local arbitrary_thing_runner = require("plugin_template._commands.arbitrary_thing.runner")
local copy_logs_runner = require("plugin_template._commands.copy_logs.runner")
local count_sheep = require("plugin_template._commands.goodnight_moon.count_sheep")
local read = require("plugin_template._commands.goodnight_moon.read")
local say_runner = require("plugin_template._commands.hello_world.say.runner")
local sleep = require("plugin_template._commands.goodnight_moon.sleep")

local M = {}

configuration.initialize_data_if_needed()

-- TODO: (you) - Change this file to whatever you need. These are just examples
M.run_arbitrary_thing = arbitrary_thing_runner.run
M.run_copy_logs = copy_logs_runner.run
M.run_hello_world_say_phrase = say_runner.run_say_phrase
M.run_hello_world_say_word = say_runner.run_say_word
M.run_goodnight_moon_read = read.run
M.run_goodnight_moon_count_sheep = count_sheep.run
M.run_goodnight_moon_sleep = sleep.run

return M
