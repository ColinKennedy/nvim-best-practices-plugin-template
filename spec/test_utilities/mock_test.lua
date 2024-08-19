--- Temporarily track when certain built-in Vim commands are called.
---
--- @module 'test_utilities.mock_test'
---

local M = {}

-- NOTE: We temporarily override vim.inspect so we can grab its
-- data for unittesting purposes. For most people using this
-- template, you can remove this text.
--
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

return M
