-- TODO: Docstring

local M = {}

local _ERROR_MESSAGES = {}
local _ORIGINAL_HEALTH_ERROR = vim.health.error

function M.get_vim_health()
    return _ERROR_MESSAGES
end

function M.mock_vim_health()
    local function _save_health_error_message(message)
        table.insert(_ERROR_MESSAGES, message)
    end

    vim.health.error = _save_health_error_message
end

function M.reset_mocked_vim_health()
    vim.health.error = _ORIGINAL_HEALTH_ERROR
    _ERROR_MESSAGES = {}
end

return M
