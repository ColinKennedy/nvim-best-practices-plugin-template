--- Temporarily track when certain built-in Vim commands are called.
---
---@module 'test_utilities.mock_test'
---

local vlog = require("plugin_template._vendors.vlog")

local M = {}

local _DATA = nil
local _ORIGINAL_DEFAULT_LEVEL
local _ORIGINAL_INSPECT = vim.inspect
local _ORIGINAL_LEVELS = {}

--- Temporarily track vim.inspect calls.
---
---@param data any The passed value(s).
---
local function _set_inspection_data(data)
    _DATA = data
end

---@return any # Get all saved vim.inspect calls.
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
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function(...) end -- luacheck: ignore 212
end

--- Revert the current `vlog` back to the last `save_logger`.
function M.reset_loggers()
    vlog._DEFAULTS.level = _ORIGINAL_DEFAULT_LEVEL

    for _, logger in ipairs(vlog._LOGGERS) do
        logger.level = _ORIGINAL_LEVELS[logger.name]
    end
end

--- Keep track of the current `vlog` so it can be `reset_loggers` later.
function M.save_loggers()
    _ORIGINAL_DEFAULT_LEVEL = vlog._DEFAULTS.level

    for _, logger in ipairs(vlog._LOGGERS) do
        _ORIGINAL_LEVELS[logger.name] = logger.level
    end
end

--- Stop stdout.
function M.silence_loggers()
    local high_level = 9999999999999999999999999999999999
    vlog._DEFAULTS.level = high_level

    for _, logger in ipairs(vlog._LOGGERS) do
        logger.level = high_level
    end
end

return M
