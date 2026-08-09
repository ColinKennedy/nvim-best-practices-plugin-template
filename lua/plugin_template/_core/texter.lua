--- Make manipulating Lua text easier.

local M = {}

--- Check if `items` is a flat array/list of string values.
---
---@param items any An array to check.
---@return boolean # If found, return `true`.
---
function M.is_string_list(items)
    if type(items) ~= "table" then
        return false
    end

    for _, item in ipairs(items) do
        if type(item) ~= "string" then
            return false
        end
    end

    return true
end

--- Check if `text` starts with `start` string.
---
---@param text string The full character / word / phrase. e.g. `"foot"`.
---@param start string The first letter(s) to check for. e.g.g `"foo"`.
---@return boolean # If found, return `true`.
---
function M.startswith(text, start)
    return text:sub(1, #start) == start
end

return M
