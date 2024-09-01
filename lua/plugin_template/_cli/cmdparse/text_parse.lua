--- Make dealing with raw text from cmdparse types easier to handle.
---
---@module 'plugin_template._cli.cmdparse.text_parse'
---

local argparse = require("plugin_template._cli.argparse")

local M = {}

--- Check if `argument` is an argument with a missing value. e.g. `--foo=`.
---
---@param argument argparse.Argument Some position, flag, or named argument.
---@return boolean # If `argument` is a named argument with no value, return `true`.
---
function M.is_incomplete_named_argument(argument)
    return argument.argument_type == argparse.ArgumentType.named and argument.value == false
end

--- Check if `text`.
---
---@param text string Some text. e.g. `--foo`.
---@return boolean # If `text` is a word, return `true.
---
function M.is_position_name(text)
    return not vim.tbl_contains(argparse.PREFIX_CHARACTERS, text:sub(1, 1))
end

--- Get the raw argument name. e.g. `"--foo"`.
---
--- Important:
---    If `argument` is a flag, this function must return back the prefix character(s) too.
---
---@param argument argparse.Argument Some named argument to get text from.
---@return string # The found name.
---
function M.get_argument_name(argument)
    return argument.name or argument.value
end

--- If the `argument` is a Named Argument with a value, get it.
---
---@param argument argparse.Argument Some user input argument to check.
---@return string # The found value, if any.
---
function M.get_argument_value_text(argument)
    local value = argument.value

    if type(value) == "boolean" then
        return ""
    end

    ---@cast value string

    return value
end

--- Get the labels of all `arguments`.
---
---@param arguments argparse.Argument[] The flag, position, or named arguments.
---@return string[] # All raw user input text.
---
function M.get_arguments_raw_text(arguments)
    local output = {}

    for _, argument in ipairs(arguments) do
        if argument.argument_type == argparse.ArgumentType.named then
            table.insert(output, string.format("%s=%s", argument.name, argument.value))
        else
            table.insert(output, argument.value or argument.name)
        end
    end

    return output
end

--- Strip argument name of any flag / prefix text. e.g. `"--foo"` becomes `"foo"`.
---
---@param text string Some raw argument name. e.g. `"--foo"`.
---@return string # The (clean) argument mame. e.g. `"foo"`.
---
function M.get_nice_name(text)
    local bad_characters = ""

    for _, prefix in ipairs(argparse.PREFIX_CHARACTERS) do
        bad_characters = bad_characters .. vim.pesc(prefix)
    end

    return (text:gsub(string.format("^[%s]+", bad_characters), ""))
end

return M
