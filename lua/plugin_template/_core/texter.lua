--- Make manipulating Lua text easier.
---
--- @module 'plugin_template._core.texter'
---

local M = {}

--- Check if `items` is a flat array/list of string values.
---
--- @param items ... An array to check.
--- @return boolean # If found, return `true`.
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

return M
