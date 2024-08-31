local M = {}

-- TODO: Docstring
-- NOTE: We temporarily override vim.inspect so we can grab its
-- data for unittesting purposes. For most people using this
-- template, you can remove this text.
--
local _ORIGINAL_INSPECT = vim.inspect
local _DATA = nil

local function _set_inspection_data(data)
    _DATA = data
end

function M.get_inspection_data()
    return _DATA
end

function M.mock_vim_inspect()
    _ORIGINAL_INSPECT = vim.inspect
    vim.inspect = _set_inspection_data
end

function M.reset_mocked_vim_inspect()
    vim.inspect = _ORIGINAL_INSPECT
end

return M
