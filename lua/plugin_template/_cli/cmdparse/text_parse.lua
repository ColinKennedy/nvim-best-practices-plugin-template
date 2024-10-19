-- TODO: Docstring

local M = {}

--- Check if `text`.
---
---@param text string Some text. e.g. `--foo`.
---@return boolean # If `text` is a word, return `true.
---
function M.is_position_name(text)
    -- TODO: Consider allowing utf-8+ characters here
    return text:sub(1, 1):match("%w")
end

--- Check all elements in `values` for `prefix` text.
---
---@param values string[] All values to check. e.g. `{"foo", "bar"}`.
---@param prefix string The prefix text to search for.
---@return string[] # All found values, if any.
---
function M.get_array_startswith(values, prefix)
    local output = {}

    for _, value in ipairs(values) do
        if vim.startswith(value, prefix) then
            table.insert(output, value)
        end
    end

    return output
end

return M
