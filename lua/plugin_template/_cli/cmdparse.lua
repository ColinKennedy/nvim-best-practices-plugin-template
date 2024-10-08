--- Parse text into positional / named arguments.
---
---@module 'plugin_template._cli.cmdparse'
---

-- TODO: Clean-up code

local _cmdparse_help = require("plugin_template._cli._cmdparse_help")
local _cmdparse_utility = require("plugin_template._cli._cmdparse_utility")
local argparse = require("plugin_template._cli.argparse")
local argparse_helper = require("plugin_template._cli.argparse_helper")
local cmdparse_constant = require("plugin_template._cli.cmdparse_constant")
local tabler = require("plugin_template._core.tabler")
local texter = require("plugin_template._core.texter")

---@alias cmdparse.Action "append" | "count" | "store_false" | "store_true" | fun(data: cmdparse.ActionData): nil
---    This controls the behavior of how parsed arguments are added into the
---    final parsed `cmdparse.Namespace`.

---@alias cmdparse.Namespace table<string, any> All parsed values.

---@alias cmdparse.MultiNumber number | "*" | "+"
---    The number of elements needed to satisfy a parameter. * == 0-or-more.
---    + == 1-or-more. A number means "we need exactly this number of
---    elements".

---@class cmdparse.ActionData
---    A struct of data that gets passed to an Parameter's action.
---@field name string
---    The parameter name to set/append/etc some `value`.
---@field namespace cmdparse.Namespace
---    The container where a parsed argument + value will go into. This
---    object gets directly modified when an action is called.
---@field value any
---    A value to add into `namespace`.

---@class cmdparse.ChoiceData
---    The information that gets passed to a typical `option.choices(...)` call.
---@field contexts cmdparse.ChoiceContext[]
---    Extra information about what caused `choices()` to be called. For
---    example we pass information like "I am currently auto-completing" or
---    other details using this value.
---@field current_value (string | string[])?
---    If the argument has an existing-written value written by the user, this
---    text is passed as `current_value`.

---@class cmdparse.ParameterInputOptions
---    All of the settings to include in a new parameter.
---@field action cmdparse.Action?
---    This controls the behavior of how parsed arguments are added into the
---    final parsed `cmdparse.Namespace`.
---@field choices (string[] | fun(data: cmdparse.ChoiceData?): string[])?
---    If included, the parameter can only accept these choices as values.
---@field count cmdparse.MultiNumber?
---    The number of times that this parameter must be written.
---@field default any?
---    When this parameter is visited, this value is added to the returned
---    `cmdparse.Namespace` assuming no other value overwrites it.
---@field destination string?
---    When a parsed `cmdparse.Namespace` is created, this field is used to store
---    the final parsed value(s). If no `destination` is given an
---    automatically assigned name is used instead.
---@field help string
---    Explain what this parser is meant to do and the parameter(s) it needs.
---    Keep it brief (< 88 characters).
---@field name string?
---    The ways to refer to this instance.
---@field names string[]?
---    The ways to refer to this instance.
---@field nargs cmdparse.MultiNumber?
---    The number of elements that this parameter consumes at once.
---@field parent cmdparse.ParameterParser?
---    The parser that owns this instance.
---@field required boolean?
---    If `true`, this parameter must get satisfying value(s) before the
---    parser is complete. If `false` then the parameter doesn't need to be
---    defined as an argument.
---@field type ("number" | "string" | fun(value: string): any)?
---    The expected output type. If a function is given, assume that the user
---    knows what they're doing and use their function's return value.
---@field value_hint string?
---    Extra text to include in --help messages. Usually to indicate
---    the sort of value that a position / named argument needs.

---@class cmdparse.ParameterOptions: cmdparse.ParameterInputOptions
---    All of the settings to include in a new parameter.
---@field choices (fun(data: cmdparse.ChoiceData?): string[])?
---    If included, the parameter can only accept these choices as values.
---@field required boolean
---    If `true`, this parameter must get satisfying value(s) before the
---    parser is complete. If `false` then the parameter doesn't need to be
---    defined as an argument.
---@field type (fun(value: string): any)?
---    The expected output type. If a function is given, assume that the user
---    knows what they're doing and use their function's return value.

---@class cmdparse.ParameterParserInputOptions
---    The options that we might pass to `cmdparse.ParameterParser.new`.
---@field choices (string[] | fun(data: cmdparse.ChoiceData?): string[])?
---    If included, the parameter can only accept these choices as values.
---@field help string
---    Explain what this parser is meant to do and the parameter(s) it needs.
---    Keep it brief (< 88 characters).
---@field name string?
---    The parser name. This only needed if this parser has a parent subparser.
---@field parent cmdparse.Subparsers?
---    A subparser that own this `cmdparse.ParameterParser`, if any.

---@class cmdparse.ParameterParserOptions: cmdparse.ParameterParserInputOptions
---    The options that we might pass to `cmdparse.ParameterParser.new`.
---@field choices (fun(data: cmdparse.ChoiceData?): string[])?
---    If included, the parameter can only accept these choices as values.

---@class cmdparse.SubparsersOptions
---    Customization options for the new cmdparse.Subparsers.
---@field destination string?
---    An internal name to track this subparser group.
---@field help string
---    Explain what types of parsers this object is meant to hold Keep it
---    brief (< 88 characters).
---@field name string
---    The identifier for all parsers under this instance.
---@field parent cmdparse.ParameterParser?
---    The parser that owns this instance, if any.
---@field required boolean?
---    If `true` then one of the parser children must be matched or the user's
---    argument input is considered invalid. If `false` then the inner parser
---    does not have to be explicitly written. Defaults to false.

---@class cmdparse.SubparsersInputOptions: cmdparse.SubparsersOptions
---    Customization options for the new cmdparse.Subparsers.
---@field [1] string?
---    A shorthand for the subparser name.

local M = {}

local _FULL_HELP_FLAG = "--help"
local _SHORT_HELP_FLAG = "-h"

local _ActionConstant = { count = "count", store_false = "store_false", store_true = "store_true" }
local _FLAG_ACTIONS = { _ActionConstant.count, _ActionConstant.store_false, _ActionConstant.store_true }

---@class cmdparse.Parameter
---    An optional / required parameter for some parser.
---@field action cmdparse.Action?
---    This controls the behavior of how parsed parameters are added into the
---    final parsed `cmdparse.Namespace`.
---@field destination string?
---    When a parsed `cmdparse.Namespace` is created, this field is used to store
---    the final parsed value(s). If no `destination` is given an
---    automatically assigned name is used instead.
---
M.Parameter = {
    __tostring = function(parameter)
        return string.format(
            "cmdparse.Parameter({names=%s, help=%s, type=%s, action=%s, "
                .. "nargs=%s, choices=%s, count=%s, required=%s, used=%s})",
            vim.inspect(parameter.names),
            vim.inspect(parameter.help),
            vim.inspect(parameter.type),
            vim.inspect(parameter._action),
            vim.inspect(parameter._nargs),
            vim.inspect(parameter.choices),
            vim.inspect(parameter._count),
            parameter.required,
            vim.inspect(parameter._used)
        )
    end,
}
M.Parameter.__index = M.Parameter

---@class cmdparse.ParameterParser
---    A starting point for parameters (positional parameters, flag parameters, etc).
---@field choices (fun(data: cmdparse.ChoiceData?): string[])?
---    If included, this parser can be referred to using these names instead of its expected name.
---@field help string
---    Explain what this parser is meant to do and the parameter(s) it needs.
---    Keep it brief (< 88 characters).
---@field name string?
---    The parser name. This only needed if this parser has a parent subparser.
---
M.ParameterParser = {
    __tostring = function(parser)
        return string.format(
            'cmdparse.ParameterParser({name="%s", help="%s", choices=%s})',
            parser.name,
            parser.help,
            parser.choices
        )
    end,
}
M.ParameterParser.__index = M.ParameterParser

---@class cmdparse.Subparsers A group of parsers.
M.Subparsers = {
    __tostring = function(subparsers)
        return string.format(
            'cmdparse.Subparsers({help="%s", destination="%s"})',
            subparsers.help,
            subparsers.destination
        )
    end,
}
M.Subparsers.__index = M.Subparsers

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
                contexts = { cmdparse_constant.ChoiceContext.position_matching },
                current_value = name,
            }),
            name
        )
    then
        return true
    end

    return false
end

--- If the `argument` is a Named Argument with a value, get it.
---
---@param argument argparse.ArgparseArgument Some user input argument to check.
---@return string # The found value, if any.
---
local function _get_argument_value_text(argument)
    local value = argument.value

    if type(value) == "boolean" then
        return ""
    end

    ---@cast value string

    return value
end

--- Check if `parameter` is expected to have exactly one value.
---
---@param parameter cmdparse.Parameter
---    A parser parameter that may expect 0-or-more values.
---@param arguments argparse.ArgparseArgument
---    User inputs to check.
---@return boolean
---    If `parameter` needs exactly one value, return `true`.
---
local function _is_single_nargs_and_named_parameter(parameter, arguments)
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

--- Check if `arguments` is valid data for `parameter`.
---
---@param parameter cmdparse.Parameter
---    A parser parameter that may expect 0-or-more values.
---@param arguments argparse.ArgparseArgument
---    User inputs to check to check against `parameter`.
---@return boolean
---    If `parameter` is satisified by is satisified by `arguments`, return `true`.
---
local function _has_satisfying_value(parameter, arguments)
    if _is_single_nargs_and_named_parameter(parameter, arguments) then
        return true
    end

    local nargs = parameter:get_nargs()

    if nargs == 0 or nargs == cmdparse_constant.Counter.zero_or_more then
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

        if count == nargs or nargs == cmdparse_constant.Counter.one_or_more then
            return true
        end
    end

    -- NOTE: There wasn't enough `arguments` left to satisfy `parameter`.
    return false
end

--- Check if `text`.
---
---@param text string Some text. e.g. `--foo`.
---@return boolean # If `text` is a word, return `true.
---
local function _is_position_name(text)
    return text:sub(1, 1):match("%w")
end

--- Check if `text` is only spaces.
---
---@param text string Some word / phrase to check. e.g. `" "`.
---@return boolean # If `text` has non-empty alphanumeric character(s), return `true`.
---
local function _is_whitespace(text)
    return text == "" or text:match("%s+")
end

-- --- Find all parsers / sub-parsers starting from `parsers`.
-- ---
-- ---@param parsers cmdparse.ParameterParser[] All child / leaf parsers to start traversing from.
-- ---
-- local function _get_all_parent_parsers(parsers)
--     local output = {}
--
--     for _, parser in ipairs(parsers) do
--         --- @type cmdparse.ParameterParser | cmdparse.Subparsers
--         local current = parser
--
--         while current do
--             table.insert(output, current)
--             current = parser._parent
--         end
--     end
--
--     return output
-- end

--- Get the raw argument name. e.g. `"--foo"`.
---
--- Important:
---    If `argument` is a flag, this function must return back the prefix character(s) too.
---
---@param argument argparse.ArgparseArgument Some named argument to get text from.
---@return string # The found name.
---
local function _get_argument_name(argument)
    return argument.name or argument.value
end

--- Check all elements in `values` for `prefix` text.
---
---@param values string[] All values to check. e.g. `{"foo", "bar"}`.
---@param prefix string The prefix text to search for.
---@return string[] # All found values, if any.
---
local function _get_array_startswith(values, prefix)
    local output = {}

    for _, value in ipairs(values) do
        if vim.startswith(value, prefix) then
            table.insert(output, value)
        end
    end

    return output
end

--- Find + increment all flag parameters of `parser` that match the other inputs.
---
---@param parser cmdparse.ParameterParser
---    A parser whose parameters may be modified.
---@param argument_name string
---    The expected flag argument name.
---@param arguments argparse.ArgparseArgument
---    All of the upcoming argumenst after `argument_name`. We use these to figure out
---    if `parser` is an exact match.
---@return boolean
---    If `true` a flag argument was matched and incremented.
---
local function _compute_exact_flag_match(parser, argument_name, arguments)
    for _, parameter in ipairs(parser:get_flag_parameters()) do
        if
            not parameter:is_exhausted()
            and vim.tbl_contains(parameter.names, argument_name)
            and _has_satisfying_value(parameter, arguments)
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
local function _compute_exact_position_match(argument_name, parser)
    for _, parameter in ipairs(parser:get_position_parameters()) do
        if not parameter:is_exhausted() then
            if _has_position_parameter_match(argument_name, parameter) then
                -- TODO: Handle this scenario. Need to do nargs checks and stuff
                parameter:increment_used()

                return true
            end

            return false
        end
    end

    return false
end

--- Remove whitespace from `text` but only if `text` is 100% whitespace.
---
---@param text string Some text to possibly strip.
---@return string # The processed `text` or, if it contains whitespace, the original `text`.
---
local function _remove_contiguous_whitespace(text)
    return (text:gsub("^%s*$", ""))
end

--- Re-order `parameters` alphabetically but put the `--help` flag at the end.
---
---@param parameters cmdparse.Parameter[] All position / flag / named parameters.
---@return cmdparse.Parameter[] # The sorted entries.
---
local function _sort_parameters(parameters)
    local output = vim.deepcopy(parameters)

    table.sort(output, function(left, right)
        if vim.tbl_contains(left.names, _FULL_HELP_FLAG) or vim.tbl_contains(left.names, _SHORT_HELP_FLAG) then
            return false
        end

        if vim.tbl_contains(right.names, _FULL_HELP_FLAG) or vim.tbl_contains(right.names, _SHORT_HELP_FLAG) then
            return true
        end

        return left.names[1] < right.names[1]
    end)

    return output
end

--- Find all child parser names under `parser`.
---
---@param parser cmdparse.ParameterParser The starting point to look for child parsers.
---@return string[] # All parser names, if any are defined.
---
local function _get_child_parser_names(parser)
    return vim.iter(_cmdparse_utility.iter_parsers(parser))
        :map(function(parser_)
            return parser_:get_names()[1]
        end)
        :totable()
end

--- Scan `input` and stop processing arguments after `column`.
---
---@param input argparse.ArgparseResults
---    The user's parsed text.
---@param column number
---    The point to stop checking for arguments. Must be a 1-or-greater value.
---@return number
---    The found index. If all arguments are < `column` then the returning
---    index will cover all of `input.arguments`.
---
local function _get_cursor_offset(input, column)
    for index, argument in ipairs(input.arguments) do
        if argument.range.end_column == column then
            return index
        elseif argument.range.end_column > column then
            return index - 1
        end
    end

    return #input.arguments
end

-- --- Get the recommended name(s) of all `parameters`.
-- ---
-- ---@param parameters cmdparse.Parameter[] All flag / position parameters to get names for.
-- ---@return string[] # The found names.
-- ---
-- local function _get_parameters_names(parameters)
--     return vim:iter(parameters)
--         :map(function(parameter)
--             return parameter.names[1]
--         end)
--         :totable()
-- end

--- Create auto-complete text for `parameter`, given some `value`.
---
---@param parameter cmdparse.Parameter
---    A parameter that (we assume) takes exactly one value that we need
---    auto-completion options for.
---@param value string
---    The user-provided (exact or partial) value for the flag / named argument
---    value, if any. e.g. the `"bar"` part of `"--foo=bar"`.
---@param contexts cmdparse.ChoiceContext[]?
---    A description of how / when this function is called. It gets passed to
---    `cmdparse.Parameter.choices()`.
---@return string[]
---    All auto-complete values, if any.
---
local function _get_single_choices_text(parameter, value, contexts)
    if not parameter.choices then
        return { parameter.names[1] .. "=" }
    end

    contexts = contexts or {}

    local output = {}

    for _, choice in
        ipairs(parameter.choices({
            contexts = vim.list_extend({ cmdparse_constant.ChoiceContext.value_matching }, contexts),
            current_value = value,
        }))
    do
        table.insert(output, parameter.names[1] .. "=" .. choice)
    end

    return output
end

--- Check all `flags` that match `prefix` and `value`.
---
---@param prefix string
---    The name of the flag that must match, exactly or partially.
---@param flags cmdparse.Parameter[]
---    All position / flag / named parameters.
---@param value string?
---    The user-provided (exact or partial) value for the flag / named argument
---    value, if any. e.g. the `"bar"` part of `"--foo=bar"`.
---@param contexts cmdparse.ChoiceContext[]?
---    A description of how / when this function is called. It gets passed to
---    `cmdparse.Parameter.choices()`.
---@return cmdparse.Parameter[]
---    The matched parameters, if any.
---
local function _get_matching_partial_flag_text(prefix, flags, value, contexts)
    local output = {}

    for _, parameter in ipairs(_sort_parameters(flags)) do
        if not parameter:is_exhausted() then
            for _, name in ipairs(parameter.names) do
                if name == prefix then
                    if parameter:get_nargs() == 1 then
                        if not value then
                            table.insert(output, parameter.names[1] .. "=")
                        else
                            vim.list_extend(output, _get_single_choices_text(parameter, value, contexts))
                        end
                    else
                        table.insert(output, name)
                    end

                    break
                elseif vim.startswith(name, prefix) then
                    if parameter:get_nargs() == 1 then
                        table.insert(output, name .. "=")
                    else
                        table.insert(output, name)
                    end

                    break
                end
            end
        end
    end

    return output
end

--- Find all `options` that match `name`.
---
--- By default a position option takes any argument / value. Some position parameters
--- have specific, required choice(s) that this function means to match.
---
---@param name string
---    The user's input text to try to match.
---@param parameters cmdparse.Parameter[]
---    All position parameters to check.
---@param contexts cmdparse.ChoiceContext[]?
---    A description of how / when this function is called. It gets passed to
---    `cmdparse.Parameter.choices()`.
---@return cmdparse.Parameter[] # The found matches, if any.
---
local function _get_matching_position_parameters(name, parameters, contexts)
    contexts = contexts or {}
    local output = {}

    for _, parameter in ipairs(_sort_parameters(parameters)) do
        if not parameter:is_exhausted() and parameter.choices then
            vim.list_extend(
                output,
                _get_array_startswith(
                    parameter.choices({
                        contexts = vim.list_extend({ cmdparse_constant.ChoiceContext.value_matching }, contexts),
                        current_value = name,
                    }),
                    name
                )
            )
        end
    end

    return output
end

--- Find all child parsers, recursively.
---
--- Note:
---     This function is **inclusive**, meaning `parser` will be returned.
---
---@param parser cmdparse.ParameterParser The starting point to look for parsers.
---@return cmdparse.ParameterParser[] # All found `parser` + child parsers.
---
local function _get_all_parsers(parser)
    local stack = { parser }
    local output = {}

    while #stack > 0 do
        local current = table.remove(stack)

        if not current then
            break
        end

        table.insert(output, current)

        for _, subparsers in ipairs(current._subparsers) do
            vim.list_extend(stack, subparsers:get_parsers())
        end
    end

    return output
end

--- Get the labels of all `arguments`.
---
---@param arguments argparse.ArgparseArgument[] The flag, position, or named arguments.
---@return string[] # All raw user input text.
---
local function _get_arguments_raw_text(arguments)
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

--- Get the label / text of `arguments`.
---
---@param arguments argparse.PositionArgument[] # Each value to serialize.
---@return string[] # The found labels, e.g. `{"foo", "bar", ...}`.
---
local function _get_position_argument_values(arguments)
    return vim.iter(arguments)
        :map(function(argument)
            return argument.value
        end)
        :totable()
end

--- Find all Argments starting with `prefix`.
---
---@param prefix string
---    The name of the flag that must match, exactly or partially.
---@param parser cmdparse.ParameterParser
---    The starting point to search within.
---@param value string?
---    If the user provided a (exact or partial) value for the flag / named
---    position, the text is given here.
---@param contexts cmdparse.ChoiceContext[]?
---    A description of how / when this function is called. It gets passed to
---    `cmdparse.Parameter.choices()`.
---@return string[] # The matching names, if any.
---
local function _get_exact_or_partial_matches(prefix, parser, value, contexts)
    prefix = _remove_contiguous_whitespace(prefix)
    local output = {}

    vim.list_extend(output, _get_matching_position_parameters(prefix, parser:get_position_parameters(), contexts))
    vim.list_extend(output, _get_matching_partial_flag_text(prefix, parser:get_flag_parameters(), value, contexts))

    -- -- TODO: Move to a function later
    -- -- NOTE: This case is for when there are multiple child parsers with
    -- -- similar names. e.g. `get-asset` & `get-assets` might both auto-complete here.
    -- --
    -- local parent_parser = parser:get_parent_parser() or parser
    --
    -- if parent_parser and not _is_whitespace(prefix) then
    --     for parser_ in _iter_parsers(parent_parser) do
    --         vim.list_extend(output, _get_array_startswith(parser_:get_names(), prefix))
    --     end
    -- end

    -- for _, parser in ipairs(parsers) do
    --     for parser_ in _iter_parsers(parser) do
    --         if vim.startswith(parser_:get_names(), argument_name) then
    --             table.insert(output, parser_)
    --         end
    --     end
    -- end

    return output
end

-- local function _get_matches(name, items)
--     local output = {}
--
--     for _, item in ipairs(items) do
--         for _, item_name in ipairs(item.names) do
--             if item_name == name then
--                 table.insert(output, item)
--
--                 break
--             end
--         end
--     end
--
--     return output
-- end

-- local function _get_flag_help_text(flag)
--     return string.format("[%s]", flag:get_raw_name())
-- end

-- local function _get_matching_position_parameters(argument, parser)
--     local output = {}
--
--     if vim.startswith(parser.name, argument) then
--         table.insert(output, parser.name)
--     end
--
--     -- TODO: Make this code more real, later
--     for _, subparsers in ipairs(parser._subparsers) do
--         for _, parser_ in ipairs(subparsers:get_parsers()) do
--             if vim.startswith(parser_.name, argument) then
--                 table.insert(output, parser_.name)
--             end
--         end
--     end
--
--     return output
-- end

-- --- Find all required parameters in `parsers` that still need value(s).
-- ---
-- ---@param parsers cmdparse.ParameterParser[] All child / leaf parsers to check.
-- ---@return cmdparse.Parameter[] # The parameters that are still unused.
-- ---
-- local function _get_incomplete_parameters(parsers)
--     local output = {}
--
--     for _, parser in ipairs(_get_all_parent_parsers(parsers)) do
--         for _, parameter in ipairs(parser:get_all_parameters()) do
--             if parameter.required and not parameter:is_exhausted() then
--                 table.insert(output, parameter)
--             end
--         end
--     end
--
--     return output
-- end

--- Find all all child parsers that start with `prefix`, starting from `parser`.
---
--- This function is **exclusive** - `parser` cannot be returned from this function.
---
---@param prefix string Some text to search for.
---@param parser cmdparse.ParameterParser The starting point to search within.
---@return string[] # The names of all matching child parsers.
---
local function _get_matching_subparser_names(prefix, parser)
    local output = {}

    for parser_ in _cmdparse_utility.iter_parsers(parser) do
        local names = parser_:get_names()

        -- TODO: All current uses of this function ended up with `prefix` ==
        -- whitespace. If so, remove this if condition later
        if _is_whitespace(prefix) then
            vim.list_extend(output, names)
        else
            vim.list_extend(output, _get_array_startswith(names, prefix))
        end
    end

    return output
end

--- Strip argument name of any flag / prefix text. e.g. `"--foo"` becomes `"foo"`.
---
---@param text string Some raw argument name. e.g. `"--foo"`.
---@return string # The (clean) argument mame. e.g. `"foo"`.
---
local function _get_nice_name(text)
    return text:match("%W*(%w+)")
end

--- Remove leading (left) whitespace `text`, if there is any.
---
---@param text string Some text e.g. `" -- "`.
---@return string # The removed text e.g. `"-- "`.
---
local function _lstrip(text)
    return (text:gsub("^%s*", ""))
end

--- Find the next arguments that need to be completed / used based on some partial `prefix`.
---
---@param parser cmdparse.ParameterParser
---    The subparser to consider for the next parameter(s).
---@param prefix string
---    Prefix text to match against for. Usually it's empty but if there's
---    a command like `foo --`, as in they started to write a flag but hasn't
---    completed, then `prefix` would be `"--"`.
---@param contexts cmdparse.ChoiceContext[]?
---    A description of how / when this function is called. It gets passed to
---    `cmdparse.Parameter.choices()`.
---@return string[]
---    The matching names, if any.
---
local function _get_next_parameters_from_remainder(parser, prefix, contexts)
    -- TODO: Consider removing this text
    -- local name = _get_argument_name(argument)
    -- local matches = vim.iter(parsers):filter(function(parser)
    --     return vim.tbl_contains(parser:get_names(), name)
    -- end):totable()
    -- -- TODO: If 2+ matches, log a warning
    -- local match = matches[1]

    local output = {}

    -- TODO: Fix the argument4 sorting here. It's broken
    -- See "dynamic argument - works with positional arguments" test
    --
    if parser:is_satisfied() then
        vim.list_extend(output, vim.fn.sort(_get_matching_subparser_names(prefix, parser)))
    end

    prefix = _lstrip(prefix)
    vim.list_extend(output, _get_exact_or_partial_matches(prefix, parser, nil, contexts))

    -- TODO: There's a bug here. We may not be able to assume the last argument like this
    -- local last = stripped.arguments[#stripped.arguments]
    -- local last_name = _get_argument_name(last)
    -- local matches = vim.iter(parsers):filter(function(parser) return parser.name == last_name end):totable()
    -- local match = matches[1]
    -- vim.list_extend(output, _get_exact_or_partial_matches(last_name, match))
    -- output = {match.name}
    -- local parent_subparsers = match._parent
    -- local parent = parent_subparsers._parent
    -- vim.list_extend(output, _get_exact_or_partial_matches(last_name, parent))
    -- output = vim.fn.sort(output)

    return output
end

-- --- Find all arguments that match `prefix`, starting from `parser.
-- ---
-- --- @param parser cmdparse.ParameterParser The starting point to search within.
-- --- @return string[] # The matching names, if any.
-- ---
-- local function _get_next_exact_or_partial_arguments(parser)
--     local output = {}
--     vim.list_extend(output, vim.fn.sort(_get_matching_subparser_names(parser)))
--     vim.list_extend(output, _get_exact_or_partial_matches(parser))
--
--     return output
-- end

--- Get all option flag / named parameter --help text from `parser`.
---
---@param parser cmdparse.ParameterParser Some runnable command to get parameters from.
---@return string[] # The labels of all of the flags.
---
local function _get_parser_flag_help_text(parser)
    local output = {}

    for _, flag in ipairs(_sort_parameters(parser:get_flag_parameters())) do
        local names = vim.fn.join(flag.names, " ")
        local text = names

        -- TODO: If this function continues to work, consider renaming
        -- `get_position_usage_help_text` to something more generic.
        --
        local hint = _cmdparse_help.get_position_usage_help_text(flag)

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

--- Get all position argument --help text from `parser`.
---
---@param parser cmdparse.ParameterParser Some runnable command to get arguments from.
---@return string[] # The labels of all of the flags.
---
local function _get_parser_position_help_text(parser)
    local output = {}

    for _, position in ipairs(parser:get_position_parameters()) do
        local text = _cmdparse_help.get_position_description_help_text(position)

        table.insert(output, texter.indent(text))
    end

    output = vim.fn.sort(output)

    if not vim.tbl_isempty(output) then
        table.insert(output, 1, "Positional Arguments:")
    end

    return output
end

-- --- Get the name(s) used to refer to `parsers`.
-- ---
-- --- Usually a parser can only be referred to by one name, in which case this
-- --- function returns one string for every parser in `parsers`. But sometimes
-- --- parsers can be referred to by several names. If that happens then the
-- --- output string will have more elements than `parsers`.
-- ---
-- ---@param parsers cmdparse.ParameterParser[] The parsers to get names from.
-- ---@return string[] # All ways to refer to `parsers`.
-- ---
-- local function _get_parsers_names(parsers)
--     local output = {}
--
--     for _, parser in ipairs(parsers) do
--         vim.list_extend(output, parser:get_names())
--     end
--
--     return output
-- end

-- --- Find all required child parsers from `parsers`.
-- ---
-- ---@param parsers cmdparse.ParameterParser[] Each parser to search within.
-- ---@return cmdparse.ParameterParser[] # The found required child parsers, if any.
-- ---
-- local function _get_unused_required_subparsers(parsers)
--     local output = {}
--
--     for _, parser in ipairs(parsers) do
--         for _, subparser in ipairs(parser._subparsers) do
--             if subparser.required then
--                 vim.list_extend(output, subparser:get_parsers())
--             end
--         end
--     end
--
--     return output
-- end

--- Print `data` but don't recurse.
---
--- If you don't call this function when you try to print one of our Parameter
--- types, it will print parent / child objects and it ends up printing the
--- whole tree. This function instead prints just the relevant details.
---
---@param data any Anything. Usually an Parameter type from this file.
---@return string # The found data.
---
local function _concise_inspect(data)
    --- NOTE: Not sure why llscheck doesn't like this line. Maybe the
    --- annotations for `vim.inspect` are incorret.
    ---
    ---@diagnostic disable-next-line redundant-parameter
    return vim.inspect(data, { depth = 1 }) or ""
end

--- Find a proper type converter from `options`.
---
---@param options cmdparse.ParameterInputOptions | cmdparse.ParameterOptions The suggested type for an parameter.
---
local function _expand_type_options(options)
    if not options.type then
        options.type = function(value)
            return value
        end
    elseif options.type == "string" then
        options.type = function(value)
            return value
        end
    elseif options.type == "number" then
        options.type = function(value)
            return tonumber(value)
        end
    elseif type(options.type) == "function" then
        -- NOTE: Do nothing. Assume the user knows what they're doing.
        return
    else
        error(string.format('Type "%s" is unknown. We can\'t parse it.', _concise_inspect(options)), 0)
    end
end

--- Add / modify `options.choices` as needed.
---
--- Basically if `options.choices` is not defined, that's fine. If it is
--- a `string` or `string[]`, handle that. If it's a function, assume the user
--- knows what they're doing and include it.
---
---@param options cmdparse.ParameterInputOptions
---    | cmdparse.ParameterOptions
---    | cmdparse.ParameterParserOptions
---    | cmdparse.ParameterParserInputOptions
---    The user-written options. (sparse or not).
---
local function _expand_choices_options(options)
    if not options.choices then
        return
    end

    local input = options.choices
    local choices

    -- TODO: Add unittests for these. Make sur ethat the user's text is
    -- passed as an import to these functions
    --
    if type(options.choices) == "string" then
        choices = function()
            return { input }
        end
    elseif texter.is_string_list(input) then
        ---@cast input string[]
        choices = function(data)
            ---@cast data cmdparse.ChoiceData

            if not data or not data.current_value then
                return input
            end

            local value = data.current_value
            ---@cast value string

            if vim.tbl_contains(data.contexts, cmdparse_constant.ChoiceContext.auto_completing) then
                return _get_array_startswith(input, value)
            end

            return input
        end
    elseif type(options.choices) == "function" then
        choices = input
    else
        error(
            string.format( -- NOTE: choices has to be a known format.
                'Got invalid "%s" choices. Expected a string[] or a function.',
                _concise_inspect(options.choices)
            ),
            0
        )
    end

    options.choices = choices
end

--- If `options` is sparsely written, "expand" all of its values. so we can use it.
---
---@param options cmdparse.ParameterInputOptions | cmdparse.ParameterOptions
---    The user-written options. (sparse or not).
---@param is_position boolean
---    If `options` is meant to be a non-flag argument. e.g. `--foo` is `false`.
---
local function _expand_parameter_options(options, is_position)
    _expand_type_options(options)
    _expand_choices_options(options)

    if options.required == nil then
        if is_position then
            options.required = true
        else
            options.required = false
        end
    end

    if vim.tbl_contains(_FLAG_ACTIONS, options.action) and not options.nargs then
        options.nargs = 0
    end

    if not options.nargs then
        options.nargs = 1
    end

    if options.required == nil then
        if is_position then
            options.required = true
        else
            options.required = false
        end
    end
end

--- Combined `namespace` with all other `...` namespaces.
---
---@param namespace cmdparse.Namespace
---    The starting namespace that will be modified.
---@param ... cmdparse.Namespace[]
---    All other namespaces to merge into `namespace`. Later entries will
---    override previous entries.
---
local function _merge_namespaces(namespace, ...)
    for _, override in ipairs({ ... }) do
        for key, value in pairs(override) do
            namespace[key] = value
        end
    end
end

--- Convert `values` according to `type_converter`.
---
---@param type_converter fun(data: any): any
---@param values (boolean | string | string[])? The values to convert.
---@return any # The converted value(s).
---
local function _resolve_value(type_converter, values)
    if type(values) ~= "table" then
        return type_converter(values)
    end

    local output = {}

    for _, value in ipairs(values) do
        table.insert(output, type_converter(value))
    end

    return output
end

--- Remove the ending `index` options from `input`.
---
---@param input argparse.ArgparseResults
---    The parsed arguments + any remainder text.
---@param column number
---    The found index. If all arguments are < `column` then the returning
---    index will cover all of `input.arguments`.
---@return argparse.ArgparseResults
---    The stripped copy from `input`.
---
local function _rstrip_input(input, column)
    local stripped = argparse_helper.rstrip_arguments(input, _get_cursor_offset(input, column))

    local last = stripped.arguments[#stripped.arguments]

    if last then
        stripped.remainder.value = input.text:sub(last.range.end_column + 1, column)
    else
        stripped.remainder.value = input.text:sub(1, column)
    end

    stripped.text = input.text:sub(1, column)

    return stripped
end

--- Make sure an `cmdparse.Parameter` has a name and every name is the same type.
---
--- If `names` is `{"foo", "-f"}` then this function will error.
---
---@param options cmdparse.ParameterInputOptions | cmdparse.ParameterOptions All data to check.
---
local function _expand_parameter_names(options)
    local function _get_type(name)
        if _is_position_name(name) then
            return "position"
        end

        return "flag"
    end

    local names = options.names or options.name or options[1]

    if type(names) == "string" then
        names = { names }
    end

    local found_type = nil

    for _, name in ipairs(names) do
        if not found_type then
            found_type = _get_type(name)
        elseif found_type ~= _get_type(name) then
            error(
                string.format(
                    "Parameter names have to be the same type. "
                        .. 'e.g. If one name starts with "-", all names '
                        .. 'must start with "-" and vice versa.'
                ),
                0
            )
        end
    end

    if not found_type then
        error(string.format('Options "%s" must provide at least one name.', vim.inspect(names)), 0)
    end

    options.names = names
end

--- Make sure `options` has no conflicting / missing data.
---
--- Raises:
---     If an issue is found.
---
---@param options cmdparse.ParameterInputOptions | cmdparse.ParameterOptions
---    All data to check.
---
local function _validate_parameter_options(options)
    if vim.tbl_contains(_FLAG_ACTIONS, options.action) then
        if options.choices ~= nil then
            error(
                string.format(
                    'Parameter "%s" cannot use action "%s" and choices at the same time.',
                    options.names[1],
                    options.action
                ),
                0
            )
        end

        if options.nargs ~= 0 then
            error(
                string.format(
                    'Parameter "%s" cannot use action "%s" and nargs at the same time.',
                    options.names[1],
                    options.action
                ),
                0
            )
        end
    end
end

--- Make sure a name was provided from `options`.
---
---@param options cmdparse.ParameterParserOptions
---
local function _validate_name(options)
    -- TODO: name is required
    if not options.name or _is_whitespace(options.name) then
        error(string.format('Parameter "%s" must have a name.', _concise_inspect(options)), 0)
    end
end

--- Create a new group of parsers.
---
---@param options cmdparse.SubparsersInputOptions | cmdparse.SubparsersOptions
---    Customization options for the new cmdparse.Subparsers.
---@return cmdparse.Subparsers
---    A group of parsers (which will be filled with parsers later).
---
function M.Subparsers.new(options)
    if not options.name and options[1] then
        options.name = options[1]
    end
    ---@cast options cmdparse.SubparsersOptions

    --- @class cmdparse.Subparsers
    local self = setmetatable({}, M.Subparsers)

    self.name = options.name
    self.visited = false -- NOTE: Noting when a child parser is used / touched
    self._parent = options.parent
    self._parsers = {}

    -- TODO: I think we can remove self.destination. Try it
    self.destination = options.destination
    self.help = options.help
    self.required = options.required or false

    return self
end

--- Check if `object` is a `cmdparse.ParameterParser`.
---
---@param object any Anything.
---@return boolean # If match, return `true`.
---
local function _is_parser(object)
    return object._flag_parameters ~= nil
end

--- Create a new `cmdparse.ParameterParser` using `options`.
---
---@param options cmdparse.ParameterParserInputOptions | cmdparse.ParameterParserOptions | cmdparse.ParameterParser
---    The options to pass to `cmdparse.ParameterParser.new`.
---@return cmdparse.ParameterParser
---    The created parser.
---
function M.Subparsers:add_parser(options)
    if _is_parser(options) then
        ---@cast options cmdparse.ParameterParser
        options:set_parent(self)
        table.insert(self._parsers, options)

        return options
    end

    ---@cast options cmdparse.ParameterParserInputOptions | cmdparse.ParameterParserOptions
    local new_options = vim.tbl_deep_extend("force", options, { parent = self })
    local parser = M.ParameterParser.new(new_options)

    table.insert(self._parsers, parser)

    return parser
end

---@return cmdparse.ParameterParser[] # Get all of the child parsers for this instance.
function M.Subparsers:get_parsers()
    return self._parsers
end

--- Create a new instance using `options`.
---
---@param options cmdparse.ParameterOptions All of the settings to include in a new parse argument.
---@return cmdparse.Parameter # The created instance.
---
function M.Parameter.new(options)
    --- @class cmdparse.Parameter
    local self = setmetatable({}, M.Parameter)

    self._action = nil
    self._count = options.count or 1
    self._nargs = options.nargs or 1
    self._type = options.type
    self._used = 0
    self.choices = options.choices
    self.default = options.default
    self.names = options.names
    self.help = options.help
    self.destination = _get_nice_name(options.destination or options.names[1])
    self:set_action(options.action)
    self.required = options.required
    self.value_hint = options.value_hint
    self._parent = options.parent

    return self
end

---@return boolean # Check if this parameter expects a fixed number of uses.
function M.Parameter:has_numeric_count()
    return type(self._count) == "number"
end

---@return boolean # Check if this instance cannot be used anymore.
function M.Parameter:is_exhausted()
    if self._count == cmdparse_constant.Counter.zero_or_more then
        return false
    end

    -- TODO: Consider 1-or-more here, too

    return self._used >= self._count
end

--- Get a function that mutates the namespace with a new parsed argument.
---
---@return fun(data: cmdparse.ActionData): nil
---    A function that directly modifies the contents of `data`.
---
function M.Parameter:get_action()
    return self._action
end

-- TODO: Consider removing this method

---@return cmdparse.MultiNumber # The number of elements that this argument consumes at once.
function M.Parameter:get_nargs()
    return self._nargs
end

---@return string # The (clean) argument mame. e.g. `"--foo"` becomes `"foo"`.
function M.Parameter:get_nice_name()
    return _get_nice_name(self.destination or self.names[1])
end

---@return string # The (raw) argument mame. e.g. `"--foo"`.
function M.Parameter:get_raw_name()
    return self.names[1]
end

--- Get a converter function that takes in a raw argument's text and outputs some converted result.
---
---@return fun(value: (string | boolean)?): any # The converter function.
---
function M.Parameter:get_type()
    return self._type
end

--- Use up more of the available use(s) of this instance.
---
--- Most arguments can only be used one time but some can be used multiple
--- times. This function takes up at least one of these available uses.
---
---@param increment number? The number of uses to consume.
---
function M.Parameter:increment_used(increment)
    increment = increment or 1
    self._used = self._used + increment
end

--- Describe how this argument should ingest new CLI value(s).
---
---@param action cmdparse.Action The selected functionality.
---
function M.Parameter:set_action(action)
    if action == _ActionConstant.store_false then
        action = function(data)
            ---@cast data cmdparse.ActionData
            data.namespace[data.name] = false
        end
    elseif action == _ActionConstant.store_true then
        action = function(data)
            ---@cast data cmdparse.ActionData
            data.namespace[data.name] = true
        end
    elseif action == _ActionConstant.count then
        action = function(data)
            ---@cast data cmdparse.ActionData
            local name = data.name
            local namespace = data.namespace

            if not namespace[name] then
                namespace[name] = 0
            end

            namespace[name] = namespace[name] + 1
        end
    elseif action == "append" then
        action = function(data)
            ---@cast data cmdparse.ActionData
            local name = data.name
            local namespace = data.namespace

            if not namespace[name] then
                namespace[name] = {}
            end

            table.insert(namespace[name], data.value)
        end
    elseif type(action) == "function" then
        action = action
    else
        action = function(data)
            ---@cast data cmdparse.ActionData
            data.namespace[data.name] = data.value
        end
    end

    self._action = action
end

-- TODO: need to add unittests for this.
--- Tell how many value(s) are needed to satisfy this instance.
---
--- e.g. nargs=2 means that every time this instance is detected there need to
--- be at least 2 values to ingest or it is not valid CLI input.
---
---@param count string | number
---    The number of values we need for this instance. `"*"` ==  0-or-more,
---    `"+"` == 1-or-more. A number means there needs to exactly that many
---    arguments (no less no more).
---
function M.Parameter:set_nargs(count)
    if count == "*" then
        count = cmdparse_constant.Counter.zero_or_more
    elseif count == "+" then
        count = cmdparse_constant.Counter.one_or_more
    end

    self._nargs = count
end

--- Create a new `cmdparse.ParameterParser`.
---
--- If the parser is a child of a subparser then this instance must be given
--- a name via `{name="foo"}` or this function will error.
---
---@param options cmdparse.ParameterParserOptions
---    The options that we might pass to `cmdparse.ParameterParser.new`.
---@return cmdparse.ParameterParser
---    The created instance.
---
function M.ParameterParser.new(options)
    if options[1] and not options.name then
        options.name = options[1]
    end

    if options.parent then
        _validate_name(options)
    end

    _expand_choices_options(options)
    --- @cast options cmdparse.ParameterParserOptions

    --- @class cmdparse.ParameterParser
    local self = setmetatable({}, M.ParameterParser)

    self.name = options.name
    self.choices = options.choices
    self.help = options.help
    self._defaults = {}
    self._position_parameters = {}
    self._flag_parameters = {}
    self._subparsers = {}
    self._parent = options.parent

    self._implicit_flag_parameters = {}
    self:_add_help_parameter()

    return self
end

--- Make a `--help` parameter and add it to this current instance.
function M.ParameterParser:_add_help_parameter()
    local parameter = self:add_parameter({
        action = function(data)
            data.namespace.execute = function(...) -- luacheck: ignore 212 unused argument
                vim.notify(self:get_full_help(""), vim.log.levels.INFO)
            end
        end,
        help = "Show this help message and exit.",
        names = { "--help", "-h" },
        nargs = 0,
    })

    -- NOTE: `self:add_parameter` just added the help flag to
    -- `self._flag_parameters` so we need to remove it (so we can add it
    -- somewhere else).
    --
    table.remove(self._flag_parameters)
    table.insert(self._implicit_flag_parameters, parameter)
end

--- Find the child parser that matches `name`.
---
---@param name string The name of a child parser within `parser`.
---@param parser cmdparse.ParameterParser The parent parser to search within.
---@return cmdparse.ParameterParser? # The matching child parser, if any.
---
local function _get_exact_subparser_child(name, parser)
    for child_parser in _cmdparse_utility.iter_parsers(parser) do
        if vim.tbl_contains(child_parser:get_names(), name) then
            return child_parser
        end
    end

    return nil
end

--- Find + increment the parameter(s) of `parser` that match the other inputs.
---
---@param parser cmdparse.ParameterParser
---    A parser whose parameters may be modified.
---@param argument_name string
---    The expected flag argument name.
---@param arguments argparse.ArgparseArgument
---    All of the upcoming argumenst after `argument_name`. We use these to figure out
---    if `parser` is an exact match.
---@return boolean
---    If `true` a flag argument was matched and incremented.
---
local function _compute_and_increment_parameter(parser, argument_name, arguments)
    local found = _compute_exact_flag_match(parser, argument_name, arguments)

    if found then
        return found
    end

    return _compute_exact_position_match(argument_name, parser)
end

-- TODO: Remove?
-- local function _get_subparser_issues(parser)
--     local output = {}
--
--     -- NOTE: If a parser has all of its parameters filled out then we can
--     -- assume that the user will try to get a subparser next.
--     --
--     for _, subparser in ipairs(parser._subparsers) do
--         if subparser.required and not subparser.visited then
--             local names = {}
--
--             for _, parser_ in ipairs(subparser:get_parsers()) do
--                 for _, name in ipairs(parser_:get_names()) do
--                     if not vim.tbl_contains(names, name) then
--                         table.insert(names, name)
--                     end
--                 end
--             end
--
--             if not vim.tbl_isempty(names) then
--                 table.insert(
--                     output,
--                     string.format(
--                         'Missing subparser "%s". Expected one of %s.',
--                         subparser.name,
--                         vim.inspect(names)
--                     )
--                 )
--             end
--         end
--     end
--
--     return output
-- end

--- Parse `arguments` and get the help summary line (the top "Usage: ..." line).
---
---@param arguments argparse.ArgparseArgument[]
---    Raw user inputs to parser for subparsers, if any.
---@return string
---    The found "Usage: ..." line.
---@return cmdparse.ParameterParser
---    The lowest parser that was found during parsing.
---
function M.ParameterParser:_get_argument_usage_summary(arguments)
    local function _get_child_parser_by_name(parser, prefix)
        for parser_ in _cmdparse_utility.iter_parsers(parser) do
            if vim.tbl_contains(parser_:get_names(), prefix) then
                return parser_
            end
        end

        return nil
    end

    local parser, _ = self:_compute_matching_parsers(arguments)

    if parser:is_satisfied() then
        local last = arguments[#arguments]

        if last then
            local last_name = _get_argument_name(last)
            parser = _get_child_parser_by_name(parser, last_name) or parser
        end
    end

    local summary = self:_get_usage_summary(parser)

    return summary, parser
end

---@return string[] # Find all unfinished parameters in this instance.
function M.ParameterParser:_get_issues()
    local output = {}

    for parameter in tabler.chain(self:get_flag_parameters(), self:get_position_parameters()) do
        if parameter.required and not parameter:is_exhausted() then
            if parameter:has_numeric_count() then
                local used = parameter._used
                local text

                if used == 0 then
                    text = string.format('Parameter "%s" must be defined.', parameter.names[1])
                else
                    text = string.format(
                        'Parameter "%s" used "%s" times but must be used "%s" times.',
                        parameter.names[1],
                        parameter._used,
                        parameter._count
                    )
                end

                if parameter.choices then
                    text = string.format(
                        '%s Valid choices are "%s"',
                        text,
                        vim.fn.join(
                            vim.fn.sorted(
                                parameter.choices({ contexts = { cmdparse_constant.ChoiceContext.error_message } })
                            ),
                            ", "
                        )
                    )
                end

                table.insert(output, text)
            end
        end
    end

    return output
end

--- Get auto-complete options based on this instance + the user's `data` input.
---
---@param data argparse.ArgparseResults | string The user input.
---@param column number? A 1-or-more value that represents the user's cursor.
---@return string[] # All found auto-complete options, if any.
---
function M.ParameterParser:_get_completion(data, column)
    if type(data) == "string" then
        data = argparse.parse_arguments(data)
    end

    local count = #data.text
    column = column or count
    local stripped = _rstrip_input(data, column)
    local remainder = stripped.remainder.value
    local output = {}

    if vim.tbl_isempty(stripped.arguments) then
        if column ~= count then
            return {}
        end

        if not _is_whitespace(remainder) then
            vim.list_extend(output, _get_matching_partial_flag_text(remainder, self:get_flag_parameters()))

            -- NOTE: If there was unparsed text then it means that the user is
            -- in the middle of an argument. We don't waot to show completion
            -- options in that situation.
            --
            return output
        end

        -- NOTE: Get all possible initial arguments
        vim.list_extend(output, vim.fn.sort(_get_matching_subparser_names("", self)))
        vim.list_extend(output, _get_matching_position_parameters("", self:get_position_parameters()))
        vim.list_extend(output, _get_matching_partial_flag_text("", self:get_flag_parameters()))

        return output
    end

    local parser, index = self:_compute_matching_parsers(stripped.arguments)
    local finished = index == #stripped.arguments - 1

    if not finished then
        error("TODO: Add support for this, somehow. Maybe.", 0)
    end

    local last = stripped.arguments[#stripped.arguments]
    local last_name = _get_argument_name(last)
    local last_value = _get_argument_value_text(last)
    local contexts = { cmdparse_constant.ChoiceContext.auto_completing }

    if remainder == "" then
        vim.list_extend(output, _get_exact_or_partial_matches(last_name, parser, last_value, contexts))

        if parser:is_satisfied() then
            for parser_ in _cmdparse_utility.iter_parsers(parser) do
                vim.list_extend(output, _get_array_startswith(parser_:get_names(), last_name))
            end
        end

        return output
    end

    -- if not parsers then
    --     -- NOTE: Something went wrong during parsing. We don't know where
    --     -- the user is in the tree so we need to exit early.
    --     --
    --     -- TODO: Check if this situation actually happens in the unittests.
    --     -- If so, add a log.
    --     --
    --     return {}
    -- end

    local child_parser = _get_exact_subparser_child(last_name, parser)

    if child_parser then
        parser = child_parser
    else
        local next_index = index + 1
        local argument_name = _get_argument_name(stripped.arguments[next_index])

        -- NOTE: If the last argument isn't a parser then it has to be
        -- a argument that matches a parameter. Find it and make sure
        -- that parameter calls `increment_used()`!
        --
        _compute_and_increment_parameter(parser, argument_name, tabler.get_slice(stripped.arguments, next_index))

        -- local found = _compute_and_increment_parameter(...
        -- if not found then
        --     -- TODO: Need to handle this case. Not sure how. Error?
        -- end
    end

    return _get_next_parameters_from_remainder(parser, remainder, contexts)

    -- -- TODO: Make this all into a function. Simplify the code
    -- vim.list_extend(output, _get_exact_or_partial_matches(last_name, parser, last_value))
    --
    -- if not _is_whitespace(last_name) then
    --     for parser_ in _iter_parsers(parser) do
    --         vim.list_extend(output, _get_array_startswith(parser_:get_names(), last_name))
    --     end
    -- end
    --
    -- vim.list_extend(output, _get_exact_or_partial_matches(last_name, parser, last_value))
    --
    -- -- TODO: Move to a function later
    -- -- NOTE: This case is for when there are multiple child parsers with
    -- -- similar names. e.g. `get-asset` & `get-assets` might both auto-complete here.
    -- --
    -- local parent_parser = parser:get_parent_parser()
    -- if parent_parser and not _is_whitespace(last_name) then
    --     for parser_ in _iter_parsers(parent_parser) do
    --         vim.list_extend(output, _get_array_startswith(parser_:get_names(), last_name))
    --     end
    -- end
    --
    -- output = vim.fn.sort(output)
    --
    -- -- local remainder = stripped.remainder.value
    -- --
    -- -- local output = {}
    -- --
    -- -- local last = stripped.arguments[#stripped.arguments]
    -- -- local last_name = _get_argument_name(last)
    --
    -- -- if remainder == "" then
    -- --     -- TODO: There's a bug here. We may not be able to assume the last argument like this
    -- --     local last = stripped.arguments[#stripped.arguments]
    -- --     local last_name = _get_argument_name(last)
    -- --     output = _get_matching_position_parameters(last_name, parser)
    -- --     output = vim.fn.sort(output)
    -- --
    -- --     return output
    -- -- end
    -- --
    -- -- vim.list_extend(output, vim.fn.sort(_get_matching_subparser_names(parser, remainder)))
    -- --
    -- -- for parameter in tabler.chain(_sort_parameters(parser._flag_parameters)) do
    -- --     table.insert(output, parameter:get_raw_name())
    -- -- end
    --
    -- return output
end

---@return cmdparse.Namespace # All default values from all (direct) child parameters.
function M.ParameterParser:_get_default_namespace()
    local output = {}

    -- TODO: Add unittests for these arg types
    for parameter in tabler.chain(self:get_position_parameters(), self:get_flag_parameters()) do
        if parameter.default then
            output[parameter:get_nice_name()] = parameter.default
        end
    end

    return output
end

-- TODO: Consider merging this code with the over traversal code
--- Search recursively for the lowest possible `cmdparse.ParameterParser` from `data`.
---
---@param data argparse.ArgparseResults All of the arguments to consider.
---@return cmdparse.ParameterParser # The found parser, if any.
---
function M.ParameterParser:_get_leaf_parser(data)
    local parser = self
    --- @cast parser cmdparse.ParameterParser

    for index, argument in ipairs(data.arguments) do
        if argument.argument_type == argparse.ArgumentType.position then
            local argument_name = _get_argument_name(argument)

            local found, found_parser =
                parser:_handle_subparsers(argparse_helper.lstrip_arguments(data, index + 1), argument_name, {})

            if not found or not found_parser then
                break
            end

            parser = found_parser
        end
    end

    return parser
end

---@return string # A one/two liner explanation of this instance's expected parameters.
function M.ParameterParser:_get_usage_summary(parser)
    local output = {}

    local names = parser:get_names()

    if #names == 1 then
        if parser:get_parent_parser() then
            table.insert(output, "{" .. names[1] .. "}")
        else
            table.insert(output, names[1])
        end
    else
        if not vim.tbl_isempty(names) then
            table.insert(output, _cmdparse_help.get_help_command_labels(names))
        end
    end

    for _, position in ipairs(parser:get_position_parameters()) do
        table.insert(output, _cmdparse_help.get_position_usage_help_text(position))
    end

    for _, flag in ipairs(_sort_parameters(parser:get_flag_parameters({ hide_implicits = true }))) do
        table.insert(output, _cmdparse_help.get_flag_help_text(flag))
    end

    local parser_names = _get_child_parser_names(parser)

    if not vim.tbl_isempty(parser_names) then
        table.insert(output, string.format("{%s}", vim.fn.join(vim.fn.sort(parser_names), ",")))
    end

    for _, flag in ipairs(_sort_parameters(parser:get_implicit_flag_parameters())) do
        table.insert(output, string.format("[%s]", flag:get_raw_name()))
    end

    -- TODO: Need to finish the concise args and also give advice on the next line
    return string.format("Usage: %s", vim.fn.join(output, " "))
end

-- --- Check if `parameter` can use `arguments`.
-- ---
-- ---@param parameter cmdparse.Parameter
-- ---    Any position / flag / named parameter.
-- ---@param arguments argparse.ArgparseArgument[]
-- ---    All of the values that we will consider applying to `parameter`.
-- ---@return string?
-- ---    A found issue, if any.
-- ---
-- local function _get_nargs_related_issue(parameter, arguments)
--     local nargs = parameter:get_nargs()
--
--     -- TODO: Need to check for nargs=+ here. And need unittest for it
--     -- TODO: Need to handle expressions, probably
--
--     if type(nargs) == "number" then
--         if nargs == 0 then
--             return nil
--         end
--
--         if nargs > #arguments then
--             return string.format('Parameter "%s" expects "%s" values.', parameter.names[1], nargs)
--         end
--
--         if nargs == 1 then
--             local argument = arguments[1]
--
--             if argument.argument_type == argparse.ArgumentType.named then
--                 return nil
--             end
--
--             -- TODO: Not sure what to do here just yet.
--             if vim.tbl_contains({ argparse.ArgumentType.flag, argparse.ArgumentType.named }, arguments[2]) then
--                 return "TODO Check if we need this implementation."
--             end
--
--             return nil
--         end
--
--         local other_arguments = tabler.get_slice(arguments, 2)
--
--         for index = 1, nargs do
--             local argument = other_arguments[index]
--
--             if
--                 not argument
--                 or argument.argument_type == argparse.ArgumentType.flag
--                 or argument.argument_type == argparse.ArgumentType.named
--             then
--                 if index == 1 then
--                     return string.format(
--                         'Parameter "%s" requires "%s" values. Got "%s" value.',
--                         parameter.names[1],
--                         nargs,
--                         index - 1
--                     )
--                 end
--
--                 return string.format(
--                     'Parameter "%s" requires "%s" values. Got "%s" values.',
--                     parameter.names[1],
--                     nargs,
--                     index - 1
--                 )
--             end
--
--             if index == nargs then
--                 return nil
--             end
--         end
--     end
--
--     return nil
-- end

-- --- Use `flag` to scan `arguments` for values to use / parse.
-- ---
-- --- Note:
-- ---     The first argument in `arguments` could literally be equivalent to
-- ---     `flag` (and often is. e.g. named arguments like `--foo=bar`).
-- ---
-- --- Raises:
-- ---     This function is partially implemented. Some corner cases might raise an error.
-- ---
-- ---@param flag cmdparse.Parameter
-- ---@return number # All consecutive `arguments` to include.
-- ---
-- local function _get_used_arguments_count(flag)
--     local nargs = flag:get_nargs()
--
--     if type(nargs) == "number" then
--         return nargs
--     end
--
--     if nargs == cmdparse_constant.Counter.one_or_more or nargs == cmdparse_constant.Counter.zero_or_more then
--         -- TODO: Add support here
--         error("TODO: Need to write this", 0)
--
--         -- for index, argument_ in ipairs(arguments) do
--         --     if argument_.argument_type ~= argparse.ArgumentType.position then
--         --         return index
--         --     end
--         -- end
--         --
--         -- return nil
--     end
--
--     error("Unknown situation. This is a bug. Fix!", 0)
-- end

--- Check `position` for matching, contiguous `arguments`.
---
---@param position cmdparse.Parameter
---    The `foo`, `bar`, etc parameter to check.
---@param arguments argparse.ArgparseArgument[]
---    The arguments to match against `positions`. Every element in `arguments`
---    is checked.
local function _get_used_position_arguments_count(position, arguments)
    local nargs = position:get_nargs()

    if type(nargs) == "number" then
        for index = 1, nargs do
            if arguments[index].argument_type ~= argparse.ArgumentType.position then
                error(
                    string.format(
                        'Parameter "%s" requires "%s" values. Got "%s" values.',
                        position.names[1],
                        nargs,
                        index
                    ),
                    0
                )
            end
        end

        return nargs
    end

    local found = 0

    for index, argument in ipairs(arguments) do
        if argument.argument_type ~= argparse.ArgumentType.position then
            return found
        end

        found = index
    end

    if nargs == cmdparse_constant.Counter.one_or_more then
        if found == 0 then
            error(string.format('Parameter "%s" requires a value.', position.names[1]), 0)
        end
    elseif type(nargs) == "number" then
        if found < nargs then
            error(
                string.format('Parameter "%s" requires "%s" values. Got "%s" value.', position.names[1], nargs, found),
                0
            )
        end
    end

    return found
end

-- --- Raise an error if `arguments` are not valid input for `flag`.
-- ---
-- --- Raises:
-- ---     If an issue is found.
-- ---
-- ---@param flag cmdparse.Parameter
-- ---    A parser option e.g. `--foo` or `--foo=bar`.
-- ---@param arguments argparse.ArgparseArgument[]
-- ---    The arguments to match against `flags`. If a match is found, the
-- ---    remainder of the arguments are treated as **values** for the found
-- ---    parameter.
-- ---
-- local function _validate_flag(flag, arguments)
--     local argument = arguments[1]
--
--     if argument.argument_type == argparse.ArgumentType.named then
--         if not argument.value or argument.value == "" then
--             error(string.format('Parameter "%s" requires 1 value.', argument.name), 0)
--         end
--     end
--
--     local issue = _get_nargs_related_issue(flag, arguments)
--
--     if issue then
--         error(issue, 0)
--     end
-- end

--- Add `flags` to `namespace` if they match `argument`.
---
--- Raises:
---     If a flag is found and a value is expected but we fail to get a value for it.
---
---@param flags cmdparse.Parameter[]
---    All `-f`, `--foo`, `-f=ttt`, and `--foo=ttt`, parameters to check.
---@param arguments argparse.ArgparseArgument[]
---    The arguments to match against `flags`. If the first element in
---    `arguments` matches one of `flags`, the **remainder** of the arguments
---    are treated as **values** for the found parameter.
---@param namespace cmdparse.Namespace
---    A container for the found match(es).
---@param contexts cmdparse.ChoiceContext[]?
---    A description of how / when this function is called. It gets passed to
---    `cmdparse.Parameter.choices()`.
---@return boolean
---    If a match was found, return `true`.
---@return number
---    The number of arguments used by the found flag, if any.
---
function M.ParameterParser:_handle_exact_flag_parameters(flags, arguments, namespace, contexts)
    contexts = contexts or {}

    local function _needs_a_value(parameter)
        local nargs = parameter._nargs

        if type(nargs) == "number" then
            return nargs ~= 0
        end

        return nargs == cmdparse_constant.Counter.one_or_more
    end

    local function _get_next_position_arguments(value_arguments)
        for index = 1, #value_arguments do
            local argument = value_arguments[index]

            if
                not argument
                or argument.argument_type == argparse.ArgumentType.flag
                or argument.argument_type == argparse.ArgumentType.named
            then
                return tabler.get_slice(value_arguments, 1, index)
            end
        end

        return value_arguments
    end

    --- Get all values from `value_arguments` according to `flag`.
    ---
    --- Raises:
    ---     If `value_arguments` does not satisfy `flag`.
    ---
    ---@param flag cmdparse.Parameter
    ---    The option to get values for, if needed.
    ---@param value_arguments argparse.ArgparseArgument[]
    ---    All of the values that we think could be related to `flag`.
    ---@return (string[] | string)?
    ---    The found value, if any.
    ---
    local function _get_flag_values(flag, value_arguments)
        local nargs = flag:get_nargs()

        -- TODO: Need to handle expressions, probably

        if nargs == cmdparse_constant.Counter.one_or_more then
            local found_arguments = _get_next_position_arguments(value_arguments)

            if vim.tbl_isempty(found_arguments) then
                error(string.format('Parameter "%s" requires 1-or-more values. Got none.', flag.names[1]), 0)
            end

            return _get_position_argument_values(found_arguments)
        end

        if nargs == cmdparse_constant.Counter.zero_or_more then
            local found_arguments = _get_next_position_arguments(value_arguments)

            return _get_position_argument_values(found_arguments)
        end

        if type(nargs) == "number" then
            if nargs == 0 then
                return nil
            end

            if nargs == 1 then
                local argument = value_arguments[1]

                if
                    not argument
                    or argument.argument_type == argparse.ArgumentType.flag
                    or argument.argument_type == argparse.ArgumentType.named
                then
                    return nil
                end

                ---@cast argument argparse.PositionArgument

                return argument.value
            end

            local values_count = #value_arguments

            if nargs > values_count then
                if values_count > 1 then
                    error(
                        string.format(
                            'Parameter "%s" requires "%s" values. Got "%s" values.',
                            flag.names[1],
                            nargs,
                            values_count
                        ),
                        0
                    )
                else
                    error(
                        string.format(
                            'Parameter "%s" requires "%s" values. Got "%s" value.',
                            flag.names[1],
                            nargs,
                            values_count
                        ),
                        0
                    )
                end
            end

            for index = 1, nargs do
                local argument = value_arguments[index]

                if
                    not argument
                    or argument.argument_type == argparse.ArgumentType.flag
                    or argument.argument_type == argparse.ArgumentType.named
                then
                    if index == 1 then
                        error(
                            string.format(
                                'Parameter "%s" requires "%s" values. Got "%s" value.',
                                flag.names[1],
                                nargs,
                                index - 1
                            )
                        )
                    end

                    error(
                        string.format(
                            'Parameter "%s" requires "%s" values. Got "%s" values.',
                            flag.names[1],
                            nargs,
                            index - 1
                        )
                    )
                end

                if index == nargs then
                    local arguments_ = tabler.get_slice(arguments, 1, nargs + 1)

                    return _get_position_argument_values(arguments_)
                end
            end

            -- TODO: Add log. This section shouldn't possibly run
            local arguments_ = tabler.get_slice(arguments, 1, nargs + 1)

            return _get_position_argument_values(arguments_)
        end
    end

    local function _validate_value_choices(values, choices, argument_name)
        if type(values) == "table" then
            local invalids = {}

            for _, value in ipairs(values) do
                if not vim.tbl_contains(choices, value) then
                    table.insert(invalids, value)
                end
            end

            if vim.tbl_isempty(invalids) then
                return
            end

            local template = 'Parameter "%s" got invalid %s value. Expected one of %s.'

            if #invalids > 1 then
                template = 'Parameter "%s" got invalid %s values. Expected one of %s.'
            end

            error(string.format(template, argument_name, vim.inspect(invalids), vim.inspect(vim.fn.sort(choices))), 0)
        end

        if not vim.tbl_contains(choices, values) then
            error(
                string.format(
                    'Parameter "%s" got invalid %s value. Expected one of %s.',
                    argument_name,
                    vim.inspect(values),
                    vim.inspect(vim.fn.sort(choices))
                ),
                0
            )
        end
    end

    local argument = arguments[1]

    if argument.argument_type == argparse.ArgumentType.named then
        if not argument.value or argument.value == "" then
            error(string.format('Parameter "%s" requires 1 value.', argument.name), 0)
        end
    end

    local value_arguments = tabler.get_slice(arguments, 2)

    for _, flag in ipairs(flags) do
        if vim.tbl_contains(flag.names, argument.name) and not flag:is_exhausted() then
            -- TODO: Need to handle expression statements here, I think. Somehow.

            local total = 1 -- NOTE: Always include the current argument in the total
            local values

            if argument.argument_type == argparse.ArgumentType.named then
                local nargs = flag:get_nargs()

                if type(nargs) == "number" and nargs ~= 1 then
                    error(string.format('Parameter "%s" requires "2" values. Got "1" value.', flag.names[1]), 0)
                end

                values = argument.value
            elseif argument.argument_type == argparse.ArgumentType.flag then
                values = _get_flag_values(flag, value_arguments)

                if values then
                    if type(values) == "string" then
                        total = total + 1
                    else
                        total = total + #values
                    end
                end
            end

            ---@cast values (string[] | string)?

            if flag.choices then
                local choices = flag.choices({
                    contexts = vim.list_extend({ cmdparse_constant.ChoiceContext.value_matching }, contexts),
                    current_value = values,
                })

                _validate_value_choices(values, choices, argument.name)
            end

            local needs_a_value = _needs_a_value(flag)

            if needs_a_value then
                if values == nil then
                    error(
                        string.format(
                            'Parameter "%s" failed to find a value. This could be a parser bug!',
                            argument.name
                        ),
                        0
                    )
                end
            end

            local name = flag:get_nice_name()
            local value = _resolve_value(flag:get_type(), values)

            if needs_a_value then
                if value == nil then
                    error(
                        string.format(
                            'Parameter "%s" failed to find a value. Please check your `type` parameter and fix it!',
                            argument.name
                        ),
                        0
                    )
                end
            end

            local action = flag:get_action()

            action({ namespace = namespace, name = name, value = value })

            -- TODO: Possible bug here. What if the `flag` has explicit
            -- choice(s) and the written value doesn't match it? I guess in
            -- that case the flag shouldn't be incremented?
            --
            flag:increment_used()

            return true, total
        end
    end

    return false, 0
end

--- Add `positions` to `namespace` if they match `argument`.
---
---@param positions cmdparse.Parameter[]
---    All `foo`, `bar`, etc parameters to check.
---@param arguments argparse.ArgparseArgument[]
---    The arguments to match against `positions`. If a match is found, the
---    remainder of the arguments are treated as **values** for the found
---    parameter.
---@param namespace cmdparse.Namespace
---    A container for the found match(es).
---@param contexts cmdparse.ChoiceContext[]?
---    A description of how / when this function is called. It gets passed to
---    `cmdparse.Parameter.choices()`.
---@return boolean
---    If a match was found, return `true`.
---@return number
---    The number of arguments used by the found flag, if any.
---
function M.ParameterParser:_handle_exact_position_parameters(positions, arguments, namespace, contexts)
    -- TODO: Consider combining this function with the other duplicate
    local function _get_values(arguments_, count)
        if count == 1 then
            return arguments_[1].value
        end

        return vim.iter(tabler.get_slice(arguments_, 1, count))
            :map(function(argument_)
                return argument_.name or argument_.value
            end)
            :totable()
    end

    contexts = contexts or {}

    for _, position in ipairs(positions) do
        if not position:is_exhausted() then
            local total = _get_used_position_arguments_count(position, arguments)

            local name = position:get_nice_name()
            local values = _get_values(arguments, total)

            if position.choices then
                local values_ = values

                if type(values) ~= "table" then
                    values_ = { values }
                end

                local choices = position.choices({
                    contexts = vim.list_extend({ cmdparse_constant.ChoiceContext.value_matching }, contexts),
                    current_value = values_,
                })

                for _, value in ipairs(values_) do
                    if not vim.tbl_contains(choices, value) then
                        error(
                            string.format(
                                'Parameter "%s" got invalid "%s" value. Expected one of %s.',
                                position.names[1],
                                value,
                                vim.inspect(vim.fn.sort(choices))
                            ),
                            0
                        )
                    end
                end
            end

            local value = _resolve_value(position:get_type(), values)
            local action = position:get_action()

            action({ namespace = namespace, name = name, value = value })

            position:increment_used()

            return true, total
        end
    end

    return false, 0
end

--- Check if `argument_name` matches a registered subparser.
---
---@param data argparse.ArgparseResults The parsed arguments + any remainder text.
---@param argument_name string A raw argument name. e.g. `foo`.
---@param namespace cmdparse.Namespace An existing namespace to set/append/etc to the subparser.
---@return boolean # If a match was found, return `true`.
---@return cmdparse.ParameterParser? # The found subparser, if any.
---
function M.ParameterParser:_handle_subparsers(data, argument_name, namespace)
    --- (Before we allow running a subparser), Make sure that there are no issues.
    local function _validate_no_issues()
        local issues = self:_get_issues()

        if not vim.tbl_isempty(issues) then
            error(vim.fn.join(issues, "\n"), 0)
        end
    end

    for _, subparser in ipairs(self._subparsers) do
        for _, parser in ipairs(subparser:get_parsers()) do
            if vim.tbl_contains(parser:get_names(), argument_name) then
                _validate_no_issues()

                parser:_parse_arguments(data, namespace)
                subparser.visited = true

                return true, parser
            end
        end
    end

    return false, nil
end

-- TODO: Consider returning just 1 parser, not a list
--- Traverse the parsers, marking arguments as used / exhausted as we traverse down.
---
---@param arguments argparse.ArgparseArgument[]
---    All user inputs to walk through.
---@return cmdparse.ParameterParser
---    The parser that was found in a current or previous iteration.
---@return number
---    A 1-or-more index value of the argument that we stopped parsing on.
---
function M.ParameterParser:_compute_matching_parsers(arguments)
    local previous_parser = nil
    local current_parser = self
    local count = #arguments

    local last_index = count - 1

    -- NOTE: We search all but the last argument here.
    -- IMPORTANT: Every argument must have a match or it means the `arguments`
    -- failed to match something in the parser tree.
    --
    for index = 1, last_index do
        local argument = arguments[index]
        local argument_name = _get_argument_name(argument)

        local found = false

        for parser_ in _cmdparse_utility.iter_parsers(current_parser) do
            if vim.tbl_contains(parser_:get_names(), argument_name) then
                found = true
                previous_parser = current_parser
                current_parser = parser_

                break
            end
        end

        if not found then
            found = _compute_and_increment_parameter(current_parser, argument_name, tabler.get_slice(arguments, index))

            if not found then
                return previous_parser or self, index
            end
        end
    end

    return current_parser, last_index

    -- -- NOTE: The last user argument is special because it might be partially written.
    -- local last = arguments[count]
    --
    -- local argument_name = ""
    --
    -- if last then
    --     -- TODO: When would this ever not be true? Remove?
    --     argument_name = _get_argument_name(last)
    -- end
    --
    -- local output = {current_parser}
    --
    -- -- TODO: Remove?
    -- -- for parser_ in _iter_parsers(current_parser) do
    -- --     if vim.startswith(parser_:get_names(), argument_name) then
    -- --         table.insert(output, parser_)
    -- --     end
    -- -- end
    --
    -- -- for _, parameter in ipairs(current_parser:get_position_parameters()) do
    -- --     if
    -- --         not parameter:is_exhausted()
    -- --         and not vim.tbl_isempty(
    -- --             _get_array_startswith(_get_recommended_position_names(parameter), argument_name)
    -- --         )
    -- --     then
    -- --         -- TODO: Handle this scenario. Need to do nargs checks and stuff
    -- --         parameter:increment_used()
    -- --     end
    -- -- end
    -- --
    -- -- -- TODO: Might need to consider choices values here.
    -- -- for _, parameter in ipairs(current_parser:get_flag_parameters()) do
    -- --     if
    -- --         not parameter:is_exhausted()
    -- --         and not vim.tbl_isempty(_get_array_startswith(parameter.names, argument_name))
    -- --     then
    -- --         -- TODO: Handle this scenario. Need to do nargs checks and stuff
    -- --         parameter:increment_used()
    -- --     end
    -- -- end
    --
    -- if _compute_exact_flag_match(current_parser, argument_name, {}) then
    --     return output
    -- end
    --
    -- if _compute_exact_position_match(current_parser, argument_name) then
    --     return output
    -- end
    --
    -- return output
end

--- Tell the user how to solve the unparseable `argument`
---
--- Raises:
---     All issue(s) found, assuming 1+ issue was found.
---
---@param argument argparse.ArgparseArgument
---    Some position / flag that we don't know what to do with.
---
function M.ParameterParser:_raise_suggested_fix(argument)
    local names = {}

    for _, parameter in ipairs(self:get_all_parameters()) do
        if parameter.required and not parameter:is_exhausted() then
            table.insert(names, parameter.names[1])
        end
    end

    -- TODO: Combine this duplicated code witgh the other code
    for _, subparser in ipairs(self._subparsers) do
        if not subparser.visited then
            for _, parser in ipairs(subparser:get_parsers()) do
                for _, name in ipairs(parser:get_names()) do
                    if not vim.tbl_contains(names, name) then
                        table.insert(names, name)
                    end
                end
            end
        end
    end

    if vim.tbl_isempty(names) then
        return
    end

    if #names == 1 then
        local message = string.format(
            'Got unexpected "%s" value. Did you mean one of this incomplete parameter? %s',
            argument.name or argument.value,
            vim.fn.join(names, "\n")
        )

        error(message, 0)
    end

    local message = string.format(
        'Got unexpected "%s" value. Did you mean one of these incomplete parameters?\n%s',
        argument.name or argument.value,
        vim.fn.join(names, "\n")
    )

    error(message, 0)
end

--- Parse user text `data`.
---
---@param data string | argparse.ArgparseResults
---    User text that needs to be parsed. e.g. `hello "World!"`
---@param namespace cmdparse.Namespace?
---    All pre-existing, default parsed values. If this is the first
---    cmdparse.ParameterParser then this `namespace` will always be empty
---    but a nested parser will usually have the parsed arguments of the
---    parent subparsers that were before it.
---@return cmdparse.Namespace
---    All of the parsed data as one group.
---
function M.ParameterParser:_parse_arguments(data, namespace)
    local function _validate_current_parser()
        -- NOTE: Because `_parse_arguments` is called recursively, this validation
        -- runs at every subparser level.
        --
        local issues = self:_get_issues()

        if not vim.tbl_isempty(issues) then
            error(vim.fn.join(issues, "\n"), 0)
        end
    end

    if type(data) == "string" then
        data = argparse.parse_arguments(data)
    end

    -- TODO: Merge namespaces more cleanly
    namespace = namespace or {}
    _merge_namespaces(namespace, self._defaults, self:_get_default_namespace())

    local position_parameters = self:get_position_parameters()
    local flag_parameters = self:get_flag_parameters()
    local found = false
    local count = #data.arguments
    local index = 1

    local contexts = { cmdparse_constant.ChoiceContext.parsing }

    while index <= count do
        local argument = data.arguments[index]

        if argument.argument_type == argparse.ArgumentType.position then
            --- @cast argument argparse.PositionArgument
            local argument_name = _get_argument_name(argument)

            found = self:_handle_subparsers(argparse_helper.lstrip_arguments(data, index + 1), argument_name, namespace)

            if found then
                -- NOTE: We can only do this because `self:_handle_subparsers`
                -- calls `_parse_arguments` which creates a recursive loop.
                -- Once we finally terminate the loop and return here the
                -- `found` is the final status of all of those recursions.
                --
                return namespace
            end

            local arguments = tabler.get_slice(data.arguments, index)
            local used_arguments
            found, used_arguments =
                self:_handle_exact_position_parameters(position_parameters, arguments, namespace, contexts)

            if not found then
                self:_raise_suggested_fix(argument)
            end

            index = index + used_arguments
        elseif
            argument.argument_type == argparse.ArgumentType.named
            or argument.argument_type == argparse.ArgumentType.flag
        then
            --- @cast argument argparse.FlagArgument | argparse.NamedArgument
            local arguments = tabler.get_slice(data.arguments, index)
            local used_arguments
            found, used_arguments = self:_handle_exact_flag_parameters(flag_parameters, arguments, namespace, contexts)

            -- if not found then
            --     -- TODO: Do something about this one
            -- end
            index = index + used_arguments
        end

        if not found then
            -- TODO: Add a unittest
            -- NOTE: We lost our place in the parse so we can't continue.

            _validate_current_parser()

            local remaining_arguments = tabler.get_slice(data.arguments, index)

            if #remaining_arguments == 1 then
                error(string.format('Unexpected argument "%s".', _get_arguments_raw_text(remaining_arguments)[1]), 0)
            end

            error(
                string.format('Unexpected arguments "%s".', vim.fn.join(_get_arguments_raw_text(remaining_arguments))),
                0
            )
        end
    end

    if not namespace.execute then
        -- IMPORTANT: This is a bit of a hack to get --help to work when a user
        -- forgets to include all arguments. It's not technically correct for
        -- us to do that and could accidentally break stuff. But If this burns
        -- us later, we can change it.
        --
        _validate_current_parser()
    end

    return namespace
end

--- (Assuming parameter counts were modified by any function) Reset counts back to zero.
function M.ParameterParser:_reset_used()
    for _, parser in ipairs(_get_all_parsers(self)) do
        for parameter in tabler.chain(parser:get_position_parameters(), parser:get_flag_parameters()) do
            parameter._used = 0
        end
    end

    -- TODO: Reset subparser.visited recursively
    for _, subparser in ipairs(self._subparsers) do
        subparser.visited = false
    end
end

-- TODO: Remove?
-- function M.ParameterParser:is_exhausted()
--     for _, parameter in ipairs(self:get_all_parameters()) do
--         if parameter.required and not parameter:is_exhausted() then
--             return false
--         end
--     end
--
--     return true
-- end

---@return boolean # If all required parameters of this instance have values.
function M.ParameterParser:is_satisfied()
    for parameter in tabler.chain(self:get_flag_parameters(), self:get_position_parameters()) do
        if parameter.required and not parameter:is_exhausted() then
            return false
        end
    end

    return true
end

--- Get all registered or implicit child parameters of this instance.
---
---@return cmdparse.Parameter # All found parameters, if any.
---
function M.ParameterParser:get_all_parameters()
    local output = {}

    for _, parameter in tabler.chain(self:get_position_parameters(), self:get_flag_parameters()) do
        table.insert(output, parameter)
    end

    return output
end

--- Get auto-complete options based on this instance + the user's `data` input.
---
---@param data argparse.ArgparseResults | string The user input.
---@param column number? A 1-or-more value that represents the user's cursor.
---@return string[] # All found auto-complete options, if any.
---
function M.ParameterParser:get_completion(data, column)
    local success, result = pcall(function()
        return self:_get_completion(data, column)
    end)

    self:_reset_used()

    if success then
        return result
    end

    error(result, 0)
end

--- Get a 1-to-2 line summary on how to run the CLI.
---
---@param data string | argparse.ArgparseResults
---    User text that needs to be parsed. e.g. `hello "World!"`
---    If `data` includes subparsers, that subparser's help message is returned instead.
---@return string
---    A one/two liner explanation of this instance's expected arguments.
---
function M.ParameterParser:get_concise_help(data)
    if type(data) == "string" then
        data = argparse.parse_arguments(data)
    end

    local summary, _ = self:_get_argument_usage_summary(data.arguments)

    return summary
end

--- Get all of information on how to run the CLI.
---
---@param data string | argparse.ArgparseResults
---    User text that needs to be parsed. e.g. `hello "World!"`
---    If `data` includes subparsers, that subparser's help message is returned instead.
---@return string
---    The full explanation of this instance's expected arguments (can be pretty long).
---
function M.ParameterParser:get_full_help(data)
    if type(data) == "string" then
        data = argparse.parse_arguments(data)
    end

    local summary, parser = self:_get_argument_usage_summary(data.arguments)

    local position_text = _get_parser_position_help_text(parser)
    local flag_text = _get_parser_flag_help_text(parser)
    local child_parser_text = _cmdparse_help.get_parser_child_parser_help_text(parser)

    local output = summary

    if not vim.tbl_isempty(position_text) then
        output = output .. "\n\n" .. vim.fn.join(position_text, "\n")
    end

    if not vim.tbl_isempty(child_parser_text) then
        output = output .. "\n\n" .. vim.fn.join(child_parser_text, "\n")
    end

    if not vim.tbl_isempty(flag_text) then
        output = output .. "\n\n" .. vim.fn.join(flag_text, "\n")
    end

    output = output .. "\n"

    return output
end

--- The flags that a user didn't add to the parser but are included anyway.
---
---@return cmdparse.Parameter[]
---
function M.ParameterParser:get_implicit_flag_parameters()
    return self._implicit_flag_parameters
end

--- Get the `--foo` style parameters from this instance.
---
---@param options {hide_implicits: boolean?}?
---    If `hide_implicits` is true, only the flag parameters that a user
---    explicitly added are returned. If `false` or not defined, all flags are
---    returned.
---@return cmdparse.Parameter[]
---    Get all arguments that can be placed in any order.
---
function M.ParameterParser:get_flag_parameters(options)
    if options and options.hide_implicits then
        return self._flag_parameters
    end

    local output = {}

    vim.list_extend(output, self._flag_parameters)
    vim.list_extend(output, self._implicit_flag_parameters)

    return output
end

---@return string[] # Get all of the (initial) auto-complete options for this instance.
function M.ParameterParser:get_names()
    if self.choices then
        return self.choices({ contexts = { cmdparse_constant.ChoiceContext.parameter_names } })
    end

    return { self.name }
end

---@return cmdparse.ParameterParser? # Get the parser that owns this parser, if any.
function M.ParameterParser:get_parent_parser()
    if not self._parent then
        return nil
    end

    ---@diagnostic disable-next-line undefined-field
    return self._parent._parent
end

---@return cmdparse.Parameter[] # Get all arguments that must be put in a specific order.
function M.ParameterParser:get_position_parameters()
    return self._position_parameters
end

--- Create a child parameter so we can use it to parse text later.
---
---@param options cmdparse.ParameterInputOptions
---    All of the settings to include in the new parameter.
---@return cmdparse.Parameter
---    The created `cmdparse.Parameter` instance.
---
function M.ParameterParser:add_parameter(options)
    _expand_parameter_names(options)
    local is_position = _is_position_name(options.names[1])
    _expand_parameter_options(options, is_position)
    --- @cast options cmdparse.ParameterOptions

    _validate_parameter_options(options)

    local new_options = vim.tbl_deep_extend("force", options, { parent = self })
    local parameter = M.Parameter.new(new_options)

    if _is_position_name(options.names[1]) then
        table.insert(self._position_parameters, parameter)
    else
        table.insert(self._flag_parameters, parameter)
    end

    return parameter
end

--- Create a group so we can add nested parsers underneath it later.
---
---@param options cmdparse.SubparsersInputOptions | cmdparse.SubparsersOptions
---    Customization options for the new cmdparse.Subparsers.
---@return cmdparse.Subparsers
---    A new group of parsers.
---
function M.ParameterParser:add_subparsers(options)
    local new_options = vim.tbl_deep_extend("force", options, { parent = self })
    local subparsers = M.Subparsers.new(new_options)

    table.insert(self._subparsers, subparsers)

    return subparsers
end

--- Parse user text `data`.
---
---@param data string | argparse.ArgparseResults
---    User text that needs to be parsed. e.g. `hello "World!"`
---@return cmdparse.Namespace
---    All of the parsed data as one group.
---
function M.ParameterParser:parse_arguments(data)
    local success, result = pcall(function()
        return self:_parse_arguments(data, {})
    end)

    self:_reset_used()

    if success then
        return result
    end

    error(result, 0)
end

--- Whenever this parser is visited add all of these values to the resulting namespace.
---
---@param data table<string, any>
---    All of the data to set onto the namespace when it's found.
---
function M.ParameterParser:set_defaults(data)
    self._defaults = data
end

--- Whenever this parser is visited, return `{execute=caller}` so people can use it.
---
---@param caller fun(any: any): any
---    A function that runs a specific parser command. e.g. a "Hello, World!" program.
---
function M.ParameterParser:set_execute(caller)
    self._defaults.execute = caller
end

-- TODO: Consider making _parent public.
function M.ParameterParser:set_parent(parser)
    self._parent = parser
end

return M
