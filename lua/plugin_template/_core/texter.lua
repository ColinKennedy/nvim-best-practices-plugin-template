--- Make manipulating Lua text easier.
---
---@module 'plugin_template._core.texter'
---

local M = {}

--- Check if `character` is a standard A-Z 0-9ish character.
---
---@param character string Some single-value to check.
---@return boolean # If it's alpha return `true`.
---
function M.is_alphanumeric(character)
    return character:match("^[A-Za-z0-9]$") ~= nil
end

--- Check if `character` is "regular" text but not alphanumeric.
---
--- Examples would be Asian characters, Arabic, emojis, etc.
---
---@param character string Some single-value to check.
---@return boolean # If found return `true`.
---
function M.is_unicode(character)
    local code_point = character:byte()

    return code_point > 127
end

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

--- Check if `character` is a space, tab, or newline.
---
---@param character string Basically `" "`, `\n`, `\t`.
---@return boolean # If it's any whitespace, return `true`.
---
function M.is_whitespace(character)
    return character:match("%s")
end

--- Add indentation to `text.
---
---@param text string Some phrase to indent one level. e.g. `"foo"`.
---@return string # The indented text, `"    foo"`.
---
function M.indent(text)
    return string.format("    %s", text)
end

return M
