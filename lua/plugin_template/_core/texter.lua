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
    return character == "" or character:match("%s+")
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

--- Add indentation to `text.
---
---@param text string Some phrase to indent one level. e.g. `"foo"`.
---@return string # The indented text, `"    foo"`.
---
function M.indent(text)
    return string.format("    %s", text)
end

--- Remove leading (left) whitespace `text`, if there is any.
---
---@param text string Some text e.g. `" -- "`.
---@return string # The removed text e.g. `"-- "`.
---
function M.lstrip(text)
    return (text:gsub("^%s*", ""))
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
