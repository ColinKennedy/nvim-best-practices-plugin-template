--- Functions that make writing / reading / changing help messages.
---
---@module 'plugin_template._cli.cmdparse.help_message'
---

local constant = require("plugin_template._cli.cmdparse.constant")
local iterator_helper = require("plugin_template._cli.cmdparse.iterator_helper")
local text_parse = require("plugin_template._cli.cmdparse.text_parse")
local texter = require("plugin_template._core.texter")

local M = {}
local _Private = {}

M.HELP_MESSAGE_PREFIX = "Usage: "
M.HELP_NAMES = { "--help", "-h" }

--- Add `items` to `table_` if it is not empty.
---
---@param table_ any[] An array to add to.
---@param items string[] Values to add into `table_`, maybe.
---
local function _insert_if_value(table_, items)
    if vim.tbl_isempty(items) then
        return
    end

    table.insert(table_, vim.fn.join(items, "\n"))
end

--- Convert `text` into an expected value hint help message text.
---
--- For example `"foo-bar"` becomes `"FOO_BAR"`. This is just for display-purposes.
---
---@param text string A parameter name to replace.
---@return string # The replaced text.
---
function _Private.get_recommended_value_hint_name(text)
    local found

    for index = 1, #text do
        local character = text:sub(index, index)

        if texter.is_alphanumeric(character) or texter.is_unicode(character) then
            found = index

            break
        end
    end

    if not found then
        return ""
    end

    local word = text:sub(found, #text)

    return (word:upper():gsub("-", "_"))
end

--- Create the help message for a parameter.
---
---@param parameter cmdparse.Parameter
---    Any position, flag, or named parameter to get a help message for.
---@return string
---    The help created message.
---
function _Private.get_parameter_usage_help_text(parameter)
    local text

    if parameter.value_hint and parameter.value_hint ~= "" then
        text = parameter.value_hint
    elseif parameter.choices then
        local choices = parameter.choices({ contexts = { constant.ChoiceContext.help_message } })

        text = "{" .. vim.fn.join(choices, ",") .. "}"
    else
        text = _Private.get_recommended_value_hint_name(parameter.names[1])
    end

    ---@cast text string

    local nargs = parameter:get_nargs()

    if type(nargs) == "number" then
        local output = {}

        for _ = 1, nargs do
            table.insert(output, text)
        end

        return vim.fn.join(output, " ")
    end

    if nargs == constant.Counter.zero_or_more then
        return string.format("[%s ...]", text)
    end

    if nargs == constant.Counter.one_or_more then
        return string.format("%s [%s ...]", text, text)
    end

    return text
end

--- Get all subcomands (child parsers) from `parser`.
---
---@param parser cmdparse.ParameterParser Some runnable command to get parameters from.
---@return string[] # The labels of all of the flags.
---
function _Private.get_parser_child_parser_help_text(parser)
    local output = {}

    for parser_ in iterator_helper.iter_parsers(parser) do
        local names = parser_:get_names()
        local text = names[1]

        if #names ~= 1 then
            text = M.get_help_command_labels(names)
        end

        if parser_.help then
            text = text .. "    " .. parser_.help
        end

        table.insert(output, texter.indent(text))
    end

    output = vim.fn.sort(output)

    if not vim.tbl_isempty(output) then
        table.insert(output, 1, "Commands:")
    end

    return output
end

--- Get all option flag / named parameter --help text from `parser`.
---
---@param parser cmdparse.ParameterParser Some runnable command to get parameters from.
---@return string[] # The labels of all of the flags.
---
function _Private.get_parser_flag_help_text(parser)
    local output = {}

    for _, flag in ipairs(iterator_helper.sort_parameters(parser:get_flag_parameters())) do
        local names = vim.fn.join(flag.names, " ")
        local text = names

        local hint = M.get_position_usage_help_text(flag)

        if hint and hint ~= "" then
            text = text .. " " .. hint
        end

        if flag.help then
            text = text .. "    " .. flag.help
        end

        table.insert(output, texter.indent(text))
    end

    if not vim.tbl_isempty(output) then
        table.insert(output, 1, "Options:")
    end

    return output
end

--- Convert a position parameter
--- Create the help message for a position parameter or subparser.
---
---@param position cmdparse.Parameter
---    Any position, flag, or named parameter to get a help message for.
---@return string
---    The help created message.
---
function _Private.get_position_description_help_text(position)
    local text = M.get_position_usage_help_text(position)

    if position.help and position.help ~= "" then
        text = text .. "    " .. position.help
    end

    return text
end

--- Get all position argument --help text from `parser`.
---
---@param parser cmdparse.ParameterParser Some runnable command to get arguments from.
---@return string[] # The labels of all of the flags.
---
function _Private.get_parser_position_help_text(parser)
    local output = {}

    for _, position in ipairs(parser:get_position_parameters()) do
        local text = _Private.get_position_description_help_text(position)

        table.insert(output, texter.indent(text))
    end

    output = vim.fn.sort(output)

    if not vim.tbl_isempty(output) then
        table.insert(output, 1, "Positional Arguments:")
    end

    return output
end

--- Check if `arguments` includes a `--help` or `-h` flag.
---
---@param arguments argparse.Argument[] All user inputs to check.
---@return boolean # If the flag is found, return `true`.
---
function M.has_help(arguments)
    for _, argument in ipairs(arguments) do
        if vim.tbl_contains(M.HELP_NAMES, text_parse.get_argument_name(argument)) then
            return true
        end
    end

    return false
end

--- Check if `text` looks like a help message from `cmdparse`.
---
---@param text string The expected message. e.g. `"Usage: "`.
---@return boolean # If `text` is just a normal text, return `true`. Otherwise return `false`.
---
function M.is_help_message(text)
    return texter.startswith(text, M.HELP_MESSAGE_PREFIX)
end

--- Get the help message for a `flag` parameter.
---
---@param flag cmdparse.Parameter A `--foo` or `--foo=bar` parameter to convert.
---@return string # The generated help message.
---
function M.get_flag_help_text(flag)
    local text = _Private.get_parameter_usage_help_text(flag)

    if text and text ~= "" then
        return string.format("[%s %s]", flag:get_raw_name(), text)
    end

    return string.format("[%s]", flag:get_raw_name())
end

--- Combine `labels` into a single-line summary (for help messages).
---
---@param labels string[] All commands to run.
---@return string # The created text.
---
function M.get_help_command_labels(labels)
    return string.format("{%s}", vim.fn.join(vim.fn.sort(labels), ","))
end

--- Get the help message for all parameters and subparsers of `parser`.
---
---@param parser cmdparse.ParameterParser
---    The root to get a help message for.
---@return string[]
---    The generated help message lines.
---
function M.get_parser_help_text_body(parser)
    local output = {}

    local position_text = _Private.get_parser_position_help_text(parser)
    local flag_text = _Private.get_parser_flag_help_text(parser)
    local child_parser_text = _Private.get_parser_child_parser_help_text(parser)

    _insert_if_value(output, position_text)
    _insert_if_value(output, child_parser_text)
    _insert_if_value(output, flag_text)

    return output
end

--- Get the help message for a typical position parameter.
---
---@param position cmdparse.Parameter A regular parameter. Not the `"--foo"` kinds.
---@return string # The created help message.
---
function M.get_position_usage_help_text(position)
    local text = _Private.get_parameter_usage_help_text(position)

    if type(position.count) == "string" then
        text = text .. position.count
    end

    return text
end

--- Print `text` to the user.
---
---@param text string a formatted help message to send.
---
function M.show_help(text)
    vim.notify(text, vim.log.levels.INFO)
end

return M
