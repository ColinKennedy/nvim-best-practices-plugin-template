--- Temporarily track when certain built-in Vim commands are called.
---
---@module 'test_utilities.mock_test'
---

local M = {}

local _ORIGINAL_INSPECT = vim.inspect
local _DATA = nil

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

return M
