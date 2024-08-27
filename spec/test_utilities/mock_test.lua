--- Temporarily track when certain built-in Vim commands are called.
---
--- @module 'test_utilities.mock_test'
---

local count_sheep_runner = require("plugin_template._commands.goodnight_moon.count_sheep.runner")
local read_runner = require("plugin_template._commands.goodnight_moon.read.runner")
local say_runner = require("plugin_template._commands.hello_world.say.runner")
local sleep_runner = require("plugin_template._commands.goodnight_moon.sleep.runner")

local M = {}

local _ORIGINAL_INSPECT = vim.inspect
local _DATA = nil

--- Temporarily track vim.inspect calls.
---
--- @param data ... The passed value(s).
---
local function _set_inspection_data(data)
    _DATA = data
end

--- @return ... # Get all saved vim.inspect calls.
function M.get_inspection_data()
    return _DATA
end

--- Temporarily track vim.inspect calls.
function M.mock_vim_inspect()
    _ORIGINAL_INSPECT = vim.inspect
    vim.inspect = _set_inspection_data
end

--- Restore the previous vim.inspect function.
function M.reset_mocked_vim_inspect()
    vim.inspect = _ORIGINAL_INSPECT
end

--- Make it so no existing API calls or commands print text.
function M.silence_all_internal_prints()
    count_sheep_runner._print = function(...) end
    read_runner._print = function(...) end
    say_runner._print = function(...) end
    sleep_runner._print = function(...) end
    vim.notify = function(...) end
end

return M
