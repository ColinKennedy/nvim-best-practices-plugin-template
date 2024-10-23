--- Parse and evaluate parameters, using CLI arguments.
---
---@module 'plugin_template._cli.cmdparse.evaluator'
---

local argparse = require("plugin_template._cli.argparse")
local constant = require("plugin_template._cli.cmdparse.constant")

local M = {}
local _Private = {}

--- Check if `name` is a possible value of `parameter`.
---
---@param name string
---    The written user text. e.g. `"foo"`.
---@param parameter cmdparse.Parameter
---    Some position parameter to check. e.g. `{choices={"foo", "bar"}}`.
---@return boolean
---    If `parameter` has defined `parameter.choices` and `name` matches one of
---    them, return `true`.
---
local function _has_position_parameter_match(name, parameter)
    if not parameter.choices then
        -- NOTE: Any value is valid if there are no explicit choices
        return true
    end

    if
        vim.tbl_contains(
            parameter.choices({
                contexts = { constant.ChoiceContext.position_matching },
                current_value = name,
            }),
            name
        )
    then
        return true
    end

    return false
end

--- Check if `arguments` is valid data for `parameter`.
---
---@param parameter cmdparse.Parameter
---    A parser parameter that may expect 0-or-more values.
---@param arguments argparse.Argument
---    User inputs to check to check against `parameter`.
---@return boolean
---    If `parameter` is satisified by is satisified by `arguments`, return `true`.
---
function _Private.has_satisfying_value(parameter, arguments)
    if _Private.is_single_nargs_and_named_parameter(parameter, arguments) then
        return true
    end

    local nargs = parameter:get_nargs()

    if nargs == 0 or nargs == constant.Counter.zero_or_more then
        -- NOTE: If `parameter` doesn't need any value then it is definitely satisified.
        return true
    end

    local count = 0

    for _, argument in ipairs(arguments) do
        if argument.argument_type ~= argparse.ArgumentType.position then
            -- NOTE: Flag arguments can only accept non-flag arguments, in general.
            return false
        end

        count = count + 1

        if count == nargs or nargs == constant.Counter.one_or_more then
            return true
        end
    end

    -- NOTE: There wasn't enough `arguments` left to satisfy `parameter`.
    return false
end

--- Check if `parameter` is expected to have exactly one value.
---
---@param parameter cmdparse.Parameter
---    A parser parameter that may expect 0-or-more values.
---@param arguments argparse.Argument
---    User inputs to check.
---@return boolean
---    If `parameter` needs exactly one value, return `true`.
---
function _Private.is_single_nargs_and_named_parameter(parameter, arguments)
    if parameter:get_nargs() ~= 1 then
        return false
    end

    local argument = arguments[1]

    if not argument then
        return false
    end

    if argument.argument_type ~= argparse.ArgumentType.named then
        return false
    end

    return vim.tbl_contains(parameter.names, argument.name)
end

--- Find + increment all flag parameters of `parser` that match the other inputs.
---
---@param parser cmdparse.ParameterParser
---    A parser whose parameters may be modified.
---@param argument_name string
---    The expected flag argument name.
---@param arguments argparse.Argument
---    All of the upcoming argumenst after `argument_name`. We use these to figure out
---    if `parser` is an exact match.
---@return boolean
---    If `true` a flag argument was matched and incremented.
---
function _Private.compute_exact_flag_match(parser, argument_name, arguments)
    for _, parameter in ipairs(parser:get_flag_parameters()) do
        if
            not parameter:is_exhausted()
            and vim.tbl_contains(parameter.names, argument_name)
            and _Private.has_satisfying_value(parameter, arguments)
        then
            parameter:increment_used()

            return true
        end
    end

    return false
end

--- Find + increment all position parameters of `parser` that match the other inputs.
---
---@param parser cmdparse.ParameterParser
---    A parser whose parameters may be modified.
---@param argument_name string
---    The expected position argument name. Most of the time position arguments
---    don't even have an expected name so this value is not always used.
---@return boolean
---    If `true` a position argument was matched and incremented.
---
function _Private.compute_exact_position_match(argument_name, parser)
    for _, parameter in ipairs(parser:get_position_parameters()) do
        if not parameter:is_exhausted() then
            if _has_position_parameter_match(argument_name, parameter) then
                parameter:increment_used()

                return true
            end

            return false
        end
    end

    return false
end

--- Find + increment the parameter(s) of `parser` that match the other inputs.
---
---@param parser cmdparse.ParameterParser
---    A parser whose parameters may be modified.
---@param argument_name string
---    The expected flag argument name.
---@param arguments argparse.Argument
---    All of the upcoming argumenst after `argument_name`. We use these to figure out
---    if `parser` is an exact match.
---@return boolean
---    If `true` a flag argument was matched and incremented.
---
function M.compute_and_increment_parameter(parser, argument_name, arguments)
    local found = _Private.compute_exact_flag_match(parser, argument_name, arguments)

    if found then
        return found
    end

    return _Private.compute_exact_position_match(argument_name, parser)
end

return M
