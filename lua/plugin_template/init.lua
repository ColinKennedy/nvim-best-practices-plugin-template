--- All function(s) that can be called externally by other Lua modules.
---
--- If a function's signature here changes in some incompatible way, this
--- package must get a new **major** version.
---
---@module 'plugin_template'
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

--- Print the `names`.
---
---@param names string[]? Some text to print out. e.g. `{"a", "b", "c"}`.
---
function M.run_arbitrary_thing(names)
    arbitrary_thing_runner.run(names)
end

--- Copy the log data from the given `path` to the user's clipboard.
---
---@param path string?
---    A path on-disk to look for logs. If none is given, the default fallback
---    location is used instead.
---
function M.run_copy_logs(path)
    copy_logs_runner.run(path)
end

--- Print `phrase` according to the other options.
---
---@param phrase string[]
---    The text to say.
---@param repeat_ number?
---    A 1-or-more value. The number of times to print `word`.
---@param style string?
---    Control how the text should be shown.
---
function M.run_hello_world_say_phrase(phrase, repeat_, style)
    say_runner.run_say_phrase(phrase, repeat_, style)
end

--- Print `phrase` according to the other options.
---
---@param word string
---    The text to say.
---@param repeat_ number?
---    A 1-or-more value. The number of times to print `word`.
---@param style string?
---    Control how the text should be shown.
---
function M.run_hello_world_say_word(word, repeat_, style)
    say_runner.run_say_word(word, repeat_, style)
end

--- Count a sheep for each `count`.
---
---@param count number Prints 1 sheep per `count`. A value that is 1-or-greater.
---
function M.run_goodnight_moon_count_sheep(count)
    count_sheep.run(count)
end

--- Print the name of the book.
---
---@param book string The name of the book.
---
function M.run_goodnight_moon_read(book)
    read.run(book)
end

--- Print Zzz each `count`.
---
---@param count number? Prints 1 Zzz per `count`. A value that is 1-or-greater.
---
function M.run_goodnight_moon_sleep(count)
    sleep.run(count)
end

return M
