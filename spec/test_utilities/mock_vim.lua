--- Temporarily track when certain built-in Vim commands are called.
---
---@module 'test_utilities.mock_vim'
---

local M = {}

local _ERROR_MESSAGES = {}
local _ORIGINAL_HEALTH_ERROR = vim.health.error

---@return string[] # Get all saved vim.health.error calls.
function M.get_vim_health_errors()
    return _ERROR_MESSAGES
end

--- Temporarily track vim.health calls.
function M.mock_vim_health()
    local function _save_health_error_message(message)
        table.insert(_ERROR_MESSAGES, message)
    end

    vim.health.error = _save_health_error_message
end

--- Restore the previous vim.health function.
function M.reset_mocked_vim_health()
    vim.health.error = _ORIGINAL_HEALTH_ERROR
    _ERROR_MESSAGES = {}
end

return M
