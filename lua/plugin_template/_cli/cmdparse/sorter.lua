--- Make sorting arguments easier.
---
---@module 'plugin_template._cli.cmdparse.sorter'
---

local argparse = require("plugin_template._cli.argparse")
local help_message = require("plugin_template._cli.cmdparse.help_message")
local texter = require("plugin_template._core.texter")

local M = {}

---@class cmdparse._sorter.ArgumentCategories
---    A series of arguments that the user wrote, split into various sections.
---@field flags table<string, string[]>
---    All arguments that starts with - / + e.g. `{"--foo", "--bar", "--fizz=buzz"}`.
---@field positions table<string, string[]>
---    All arguments that don't start with - / + e.g. `{"foo", "bar", "fizz", "buzz"}`.

--- Check if `text` is starts with a typical - or +.
---
---@param text string An argument. e.g. `"--foo"`.
---@return boolean # If it starts with - or +, return `true`.
---
local function _is_flag(text)
    for _, prefix in ipairs(argparse.PREFIX_CHARACTERS) do
        if texter.startswith(text, prefix) then
            return true
        end
    end

    return false
end

--- Get the starting text of a named argument.
---
---@param text string Some flag text. e.g. `"--foo-bar=thing"`.
---@return string # The found name, if any. e.g. `"--foo"`.
---
local function _get_base_name(text)
    return (text:match("(.+)=")) or ""
end

--- Split `arguments` based on what type they are.
---
---@param arguments string[]
---    The values to categorize based on if they are a position, flag, or named argument.
---    e.g. `{"a", "z", "b", "--named=foo", "--help", "--named=bar", "-a", "-z"}`
---@return cmdparse._sorter.ArgumentCategories
---    The arguments by-category. e.g. `{flags={"--named=foo", "--help",
---    "--named=bar", "-a", "-z"}, positions={"a", "z", "b"}}`.
---
function M.categorize_arguments(arguments)
    local categories = { flags = {}, positions = {} }

    for _, argument in ipairs(arguments) do
        if _is_flag(argument) then
            local base_name = _get_base_name(argument)

            if base_name == "" then
                if not vim.tbl_contains(vim.tbl_keys(categories.flags), argument) then
                    categories.flags[argument] = { argument }
                end
            else
                if not vim.tbl_contains(vim.tbl_keys(categories.flags), base_name) then
                    categories.flags[base_name] = {}
                end

                table.insert(categories.flags[base_name], argument)
            end
        else
            if not vim.tbl_contains(vim.tbl_keys(categories.positions), argument) then
                categories.flags = {}
            end

            table.insert(categories.positions, argument)
        end
    end

    return categories
end

--- Sort the flag and named arguments by our conventions.
---
--- - Double-dash flags and names are mixed
--- - Flags are alphabetically sorted
--- - Named flags are also alphabetically sorted
---     - But their values, which come directly from the user, are not sorted!
--- - Certain, known flags that are not likely to be picked go at the end. e.g. --help.
---
---@param arguments cmdparse._sorter.ArgumentCategories
---    The values to sort. e.g. `{"b", "a", "zzz" "--help", "-a", "--zoo", "--abc",
---    "--named=a", "--named=c", "--named=b"}`.
---@return string[]
---    The sorted output. `{"a", "b", "zzz" "--abc", "--named=a", "--named=c",
---    "--named=b", "--zoo", "-a", "--help"}`.
---
function M.sort_and_flatten_flags(arguments)
    local output = {}

    local found_help_names = {}

    for _, key in ipairs(vim.fn.sort(vim.tbl_keys(arguments))) do
        for _, value in ipairs(arguments[key]) do
            if vim.tbl_contains(help_message.HELP_NAMES, value) then
                table.insert(found_help_names, value)
            else
                table.insert(output, value)
            end
        end
    end

    for _, value in ipairs(found_help_names) do
        table.insert(output, value)
    end

    return output
end

return M
