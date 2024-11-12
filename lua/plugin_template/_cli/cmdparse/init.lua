--- Parse text into positional / named arguments.
---
---@module 'plugin_template._cli.cmdparse'
---

local argparse = require("plugin_template._cli.argparse")
local argparse_helper = require("plugin_template._cli.argparse_helper")
local configuration = require("plugin_template._core.configuration")
local constant = require("plugin_template._cli.cmdparse.constant")
local evaluator = require("plugin_template._cli.cmdparse.evaluator")
local help_message = require("plugin_template._cli.cmdparse.help_message")
local iterator_helper = require("plugin_template._cli.cmdparse.iterator_helper")
local matcher = require("plugin_template._cli.cmdparse.matcher")
local sorter = require("plugin_template._cli.cmdparse.sorter")
local tabler = require("plugin_template._core.tabler")
local text_parse = require("plugin_template._cli.cmdparse.text_parse")
local texter = require("plugin_template._core.texter")
local types_input = require("plugin_template._cli.cmdparse.types_input")

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

---@class cmdparse._core.DisplayOptions
---    Control minor behaviors of this function. e.g. What data to show.
---@field excluded_names string[]?
---    Prevent parameters from returning from functions if they are in this
---    list. e.g. don't show any parameter in during auto-completion if it is
---    in `excluded_names`.

local vlog = require("plugin_template._vendors.vlog")

local M = {}
local _Private = {}

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
            vim.inspect(parameter.count),
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

--- Check if `data` wants to show "--help" flags during cmdparse commands.
---
---@param data plugin_template.ConfigurationCmdparseAutoComplete?
---    The user settings to read from, if any. If no data is given, the user's
---    default configuration is used insteand.
---@return boolean
---    If `true` then the --help flag should be down. If `false`, don't.
---
local function _is_help_flag_enabled(data)
    local value

    if data then
        value = tabler.get_value(data, { "display", "help_flag" })
    else
        value = tabler.get_value(configuration.DATA, { "cmdparse", "auto_complete", "display", "help_flag" })
    end

    if value == nil then
        return true
    end

    return value
end

--- Check if `object` is a `cmdparse.ParameterParser`.
---
---@param object any Anything.
---@return boolean # If match, return `true`.
---
local function _is_parser(object)
    return object._flag_parameters ~= nil
end

--- Check if `object` is a `cmdparse.Parameter`.
---
---@param object any Anything.
---@return boolean # If match, return `true`.
---
local function _is_parameter(object)
    return object._parent and not _is_parser(object)
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

        for _, subparsers in ipairs(current:get_subparsers()) do
            vim.list_extend(stack, subparsers:get_parsers())
        end
    end

    return output
end

--- Find the first subparser that matches `prefix`, if any.
---
---@param parser cmdparse.ParameterParser The starting point to look for parsers.
---@param prefix string An expected name. e.g. `"sub-command"`.
---@return cmdparse.ParameterParser? # The found subparser, if any.
---
local function _get_child_parser_by_name(parser, prefix)
    for parser_ in iterator_helper.iter_parsers(parser) do
        if vim.tbl_contains(parser_:get_names(), prefix) then
            return parser_
        end
    end

    return nil
end

--- Find all child parser names under `parser`.
---
---@param parser cmdparse.ParameterParser The starting point to look for child parsers.
---@return string[] # All parser names, if any are defined.
---
local function _get_child_parser_names(parser)
    return vim.iter(iterator_helper.iter_parsers(parser))
        :map(function(parser_)
            return parser_:get_names()[1]
        end)
        :totable()
end

--- Scan `input` and stop processing arguments after `column`.
---
---@param input argparse.Results
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

--- Complete values for `argument`, using choices from `parameter`.
---
---@param parameter cmdparse.Parameter
---    The named parameter to query from.
---@param argument argparse.Argument
---    The actual user input to include in the auto-complete result.
---@param contexts cmdparse.ChoiceContext[]
---    Extra information about what caused `choices()` to be called.
---@return string[]
---    The generated output. e.g. `--foo=bar`, `--foo=fizz`, `--foo=buzz`, etc.
---
local function _get_named_argument_completion_choices(parameter, argument, contexts)
    if not parameter.choices then
        return {}
    end

    local prefix = argument.name
    local current_value = argument.value
    ---@cast current_value string
    local output = {}

    for _, choice in
        ipairs(parameter.choices({
            contexts = vim.list_extend({ constant.ChoiceContext.value_matching }, contexts),
            current_value = current_value,
        }))
    do
        table.insert(output, string.format("%s=%s", prefix, choice))
    end

    return output
end

--- Decide from `data` what should be displayed to a user (e.g. during auto-complete).
---
---@param options plugin_template.ConfigurationCmdparseAutoComplete?
---    The user settings to read from, if any. If no data is given, the user's
---    default configuration is used insteand.
---@return cmdparse._core.DisplayOptions
---    If `true` then the --help flag should be down. If `false`, don't.
---
local function _get_display_options(options)
    local output = { excluded_names = {} }

    if not _is_help_flag_enabled(options) then
        vim.list_extend(output.excluded_names, help_message.HELP_NAMES)
    end

    return output
end

--- Get the next parameter that matches `argument` or fallback to `parameter`.
---
--- If `parameter` is a position then `argument` must a new parameter
--- because `parameter` would only be found if its arguments were satisfied.
---
--- If `parameter` is a flag then and `argument` is a position then
--- `argument` could either be the starting value for another parameter or
--- an additional value for `parameter`. We aren't sure.
---
--- If `parameter is a flag and `argument` is not a position then `argument`
--- is definitely a starting value for another parameter.
---
---@param parser cmdparse.ParameterParser The direct parent to look within.
---@param parameter cmdparse.Parameter A fallback parameter to use.
---@param argument argparse.Argument The next position that we think we can match.
---@return cmdparse.Parameter # The recommended parameter that should be used next.
---
local function _get_next_parameter_if_needed(parser, parameter, argument)
    if parameter:is_position() then
        if argument.argument_type == argparse.ArgumentType.position then
            local positions = parser:get_position_parameters()

            for _, position in ipairs(positions) do
                if not position:is_exhausted() then
                    return position
                end
            end

            return positions[#positions]
        end

        error("Bug encountered. Normally this situation cannot come up. Add a better error message here.")
    end

    if argument.argument_type ~= argparse.ArgumentType.position then
        local name = argument.name

        for _, flag in ipairs(parser:get_flag_parameters()) do
            if not flag:is_exhausted() and not vim.tbl_isempty(texter.get_array_startswith(flag.names, name)) then
                return flag
            end
        end

        return parameter
    end

    -- NOTE: We aren't sure if `argument` is for `parameter` or another, next parameter.
    -- Until we have concrete cases let's just return the original parameter.
    --
    return parameter
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

--- Check `position` for matching, contiguous `arguments`.
---
---@param position cmdparse.Parameter
---    The `foo`, `bar`, etc parameter to check.
---@param arguments argparse.Argument[]
---    The arguments to match against `positions`. Every element in `arguments`
---    is checked.
---@return number
---    The number of `arguments` that match `position`'s requirements.
---
local function _get_used_position_arguments_count(position, arguments)
    local function _error(index, nargs)
        local template = 'Parameter "%s" requires "%s" values. Got "%s"'

        if index < 2 then
            template = template .. " value."
        else
            template = template .. " values."
        end

        error(string.format(template, position.names[1], nargs, index), 0)
    end

    local nargs = position:get_nargs()

    if type(nargs) == "number" then
        for index = 1, nargs do
            local argument = arguments[index]

            if not argument then
                _error(index - 1, nargs)
            end

            if argument.argument_type ~= argparse.ArgumentType.position then
                _error(index, nargs)
            end
        end

        return nargs
    end

    return _Private.validate_variable_position_arguments(nargs, arguments, position.names[1])
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
---@param input argparse.Results
---    The parsed arguments + any remainder text.
---@param column number
---    The found index. If all arguments are < `column` then the returning
---    index will cover all of `input.arguments`.
---@return argparse.Results
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

--- Check if `argument` is available to parse in `parser`.
---
---@param argument argparse.Argument
---    Some position, flag, or named user argument.
---@param parser cmdparse.ParameterParser
---    The direct parent to look within.
---@param contexts cmdparse.ChoiceContext[]?
---    A description of how / when this function is called. It gets passed to
---    `cmdparse.Parameter.choices()`.
---@return boolean
---    If `argument` has a parameter that matches, return `true`.
---
local function _validate_last_argument(argument, parser, contexts)
    contexts = contexts or {}

    if argument.argument_type == argparse.ArgumentType.position then
        local argument_name = text_parse.get_argument_name(argument)

        if vim.tbl_contains(parser:get_names(), argument_name) then
            return true
        end

        for _, position in ipairs(parser:get_position_parameters()) do
            if not position:is_exhausted() then
                if not position.choices then
                    return true
                else
                    local value = text_parse.get_argument_value_text(argument)
                    local choices = position.choices({
                        contexts = vim.list_extend({ constant.ChoiceContext.value_matching }, contexts),
                        current_value = value,
                    })

                    return vim.tbl_contains(choices, value)
                end
            end
        end

        return false
    elseif argument.argument_type == argparse.ArgumentType.flag then
        local argument_name = text_parse.get_argument_name(argument)

        for _, flag in ipairs(parser:get_flag_parameters()) do
            if not flag:is_exhausted() and vim.tbl_contains(flag.names, argument_name) then
                return true
            end
        end

        return false
    elseif argument.argument_type == argparse.ArgumentType.named then
        local argument_name = text_parse.get_argument_name(argument)

        for _, named in ipairs(parser:get_flag_parameters()) do
            if not named:is_exhausted() and vim.tbl_contains(named.names, argument_name) then
                if not named.choices then
                    return true
                else
                    local value = text_parse.get_argument_value_text(argument)
                    local choices = named.choices({
                        contexts = vim.list_extend({ constant.ChoiceContext.value_matching }, contexts),
                        current_value = value,
                    })

                    if vim.tbl_contains(choices, value) then
                        return true
                    end
                end
            end
        end

        return false
    end

    vlog.fmt_error('Unknown argument type "%s" found and we don\'t know how to check it.', argument)

    return false
end

--- Get the "top line" of a typical --help message.
---
---@param parser cmdparse.ParameterParser The root parser to get a summary for.
---@return string # A one/two liner explanation of this instance's expected parameters.
---
function _Private.get_usage_summary(parser)
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
            table.insert(output, help_message.get_help_command_labels(names))
        end
    end

    for _, position in ipairs(parser:get_position_parameters()) do
        table.insert(output, help_message.get_position_usage_help_text(position))
    end

    for _, flag in ipairs(iterator_helper.sort_parameters(parser:get_flag_parameters({ hide_implicits = true }))) do
        table.insert(output, help_message.get_flag_help_text(flag))
    end

    local parser_names = _get_child_parser_names(parser)

    if not vim.tbl_isempty(parser_names) then
        table.insert(output, string.format("{%s}", vim.fn.join(vim.fn.sort(parser_names), ",")))
    end

    for _, flag in ipairs(iterator_helper.sort_parameters(parser:get_implicit_flag_parameters())) do
        table.insert(output, string.format("[%s]", flag:get_raw_name()))
    end

    return help_message.HELP_MESSAGE_PREFIX .. vim.fn.join(output, " ")
end

--- Make sure `arguments` satisfies `nargs`.
---
--- Raises:
---     If `arguments` fails to meet the requirements of `nargs`.
---
---@param nargs number | cmdparse.Counter
---    A fixed number or "0-or-more" or "1-or-more" etc. Basically it's the
---    condition that this function must satisfy or raise an exception.
---@param arguments argparse.Argument[]
---    All user input to consider.
---@param name string
---    The parameter where this validation originated from. Used just for the
---    error message.
---@return number
---    The number of "satisfying" `arguments`. If `nargs` is a number then this
---    return value will always be `nargs`. But if `nargs` is "0-or-more" or
---    "1-or-more" etc then the returned number could be less-than-or-equal to `nargs`.
---
function _Private.validate_variable_position_arguments(nargs, arguments, name)
    local found = 0

    for index, argument in ipairs(arguments) do
        if argument.argument_type ~= argparse.ArgumentType.position then
            return found
        end

        found = index
    end

    if nargs == constant.Counter.one_or_more then
        if found == 0 then
            error(string.format('Parameter "%s" requires a value.', name), 0)
        end
    elseif type(nargs) == "number" then
        if found < nargs then
            local template = 'Parameter "%s" requires "%s" values. Got "%s"'

            if found == 1 then
                template = template .. " value."
            else
                template = template .. " values."
            end

            error(string.format(template, name, nargs, found), 0)
        end
    end

    return found
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

    self.help = options.help
    self.required = options.required or false

    return self
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
    self._action_type = nil
    self._nargs = options.nargs or 1
    self._type = options.type
    self._used = 0
    self.choices = options.choices
    self.count = options.count or 1
    self.default = options.default
    self.names = options.names
    self.help = options.help
    self.destination = text_parse.get_nice_name(options.destination or options.names[1])
    self:set_action(options.action)
    self.required = options.required
    self.value_hint = options.value_hint
    self._parent = options.parent

    return self
end

---@return boolean # Check if this parameter expects a fixed number of uses.
function M.Parameter:has_numeric_count()
    return type(self.count) == "number"
end

---@return boolean # Check if this instance cannot be used anymore.
function M.Parameter:is_exhausted()
    if self.count == constant.Counter.zero_or_more then
        return false
    end

    return self._used >= self.count
end

---@return boolean # If this instance is a flag like `--foo` or `--foo=bar`, return `false`.
function M.Parameter:is_position()
    return text_parse.is_position_name(self.names[1])
end

---@return fun(data: cmdparse.ActionData): nil # A function that directly modifies the contents of `data`.
function M.Parameter:get_action()
    return self._action
end

---@return cmdparse.Action # The original action type. e.g. `"store_true"`.
function M.Parameter:get_action_type()
    return self._action_type
end

---@return cmdparse.MultiNumber # The number of elements that this argument consumes at once.
function M.Parameter:get_nargs()
    return self._nargs
end

---@return string # The (clean) argument mame. e.g. `"--foo"` becomes `"foo"`.
function M.Parameter:get_nice_name()
    return text_parse.get_nice_name(self.destination or self.names[1])
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
    self._action_type = action

    if action == constant.Action.store_false then
        action = function(data)
            ---@cast data cmdparse.ActionData
            data.namespace[data.name] = false
        end
    elseif action == constant.Action.store_true then
        action = function(data)
            ---@cast data cmdparse.ActionData
            data.namespace[data.name] = true
        end
    elseif action == constant.Action.count then
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

--- Tell how many value(s) are needed to satisfy this instance.
---
--- e.g. nargs=2 means that every time this instance is detected there need to
--- be at least 2 values to ingest or it is not valid CLI input.
---
--- Raises:
---     If `count` isn't a valid input.
---
---@param count string | number
---    The number of values we need for this instance. `"*"` ==  0-or-more,
---    `"+"` == 1-or-more. A number means there needs to exactly that many
---    arguments (no less no more).
---
function M.Parameter:set_nargs(count)
    if type(count) == "string" then
        if count == "*" then
            count = constant.Counter.zero_or_more
        elseif count == "+" then
            count = constant.Counter.one_or_more
        end

        error(string.format('The given string count "%s" must be + or * or a number.'))
    end

    self._nargs = count
end

--- Create a new `cmdparse.ParameterParser`.
---
--- If the parser is a child of a subparser then this instance must be given
--- a name via `{name="foo"}` or this function will error.
---
---@param options cmdparse.ParameterParserInputOptions | cmdparse.ParameterParserOptions
---    The options that we might pass to `cmdparse.ParameterParser.new`.
---@return cmdparse.ParameterParser
---    The created instance.
---
function M.ParameterParser.new(options)
    if options[1] and not options.name then
        options.name = options[1]
    end

    if options.parent then
        ---@cast options cmdparse.ParameterParserOptions
        types_input.validate_name(options)
    end

    types_input.expand_choices_options(options)
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

--- Parse `arguments` and get the help summary line (the top "Usage: ..." line).
---
---@param data argparse.Results
---    User text that needs to be parsed.
---@param parser cmdparse.ParameterParser?
---    The root parser to get a summary for. If no parser is given,
---    we auto-find it using `data`.
---@return string
---    The found "Usage: ..." line.
---@return cmdparse.ParameterParser
---    The lowest parser that was found during parsing.
---
function M.ParameterParser:_get_argument_usage_summary(data, parser)
    if not parser then
        parser = self:_compute_matching_parsers(data)
    end

    if parser:is_satisfied() then
        local last = data.arguments[#data.arguments]

        if last then
            local last_name = text_parse.get_argument_name(last)
            parser = _get_child_parser_by_name(parser, last_name) or parser
        end
    end

    local summary = _Private.get_usage_summary(parser)

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
                        parameter.count
                    )
                end

                if parameter.choices then
                    text = string.format(
                        '%s Valid choices are "%s"',
                        text,
                        vim.fn.join(
                            vim.fn.sorted(parameter.choices({ contexts = { constant.ChoiceContext.error_message } })),
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
---@param data argparse.Results | string
---    The user input.
---@param column number?
---    A 1-or-more value that represents the user's cursor.
---@param options plugin_template.ConfigurationCmdparseAutoComplete?
---    The user settings to read from, if any. If no data is given, the user's
---    default configuration is used insteand.
---@return string[]
---    All found auto-complete options, if any.
---
function M.ParameterParser:_get_completion(data, column, options)
    if type(data) == "string" then
        data = argparse.parse_arguments(data)
    end

    local display_options = _get_display_options(options)
    local count = #data.text
    column = column or count
    local stripped = _rstrip_input(data, column)
    local remainder = stripped.remainder.value
    local output = {}

    if vim.tbl_isempty(stripped.arguments) then
        if column ~= count then
            -- NOTE: The user is in an unknown column but with no arguments.
            -- This probably is an error, just return nothing.
            --
            return {}
        end

        if not texter.is_whitespace(remainder) then
            vim.list_extend(
                output,
                matcher.get_matching_partial_flag_text(
                    remainder,
                    self:get_flag_parameters(),
                    nil,
                    { constant.ChoiceContext.auto_completing },
                    display_options
                )
            )

            -- NOTE: If there was unparsed text then it means that the user is
            -- in the middle of an argument. We don't want to show completion
            -- options in that situation.
            --
            return output
        end

        vim.list_extend(output, matcher.get_current_parser_completions(self, display_options))

        return output
    end

    local contexts = { constant.ChoiceContext.auto_completing }
    local parser, recent_item, index = self:_compute_matching_parsers(stripped, contexts)
    local finished = index == #stripped.arguments

    if not finished then
        vlog.fmt_error('Could not fully parse "%s".', stripped)

        return {}
    end

    local last = stripped.arguments[#stripped.arguments]
    local last_name = text_parse.get_argument_name(last)

    local is_allowed_to_match_partial_results = remainder == ""

    if is_allowed_to_match_partial_results then
        if _is_parser(recent_item) then
            local last_value = text_parse.get_argument_value_text(last)
            ---@cast recent_item cmdparse.ParameterParser
            vim.list_extend(
                output,
                matcher.get_parser_exact_or_partial_matches(recent_item, last_name, last_value, contexts)
            )
        elseif text_parse.is_incomplete_named_argument(last) then
            ---@cast recent_item cmdparse.Parameter
            local parameter = _get_next_parameter_if_needed(parser, recent_item, last)
            vim.list_extend(output, _get_named_argument_completion_choices(parameter, last, contexts))
        elseif _is_parameter(recent_item) then
            ---@cast recent_item cmdparse.Parameter
            local parameter = _get_next_parameter_if_needed(parser, recent_item, last)

            if not parameter then
                return {}
            end

            vim.list_extend(
                output,
                matcher.get_exact_or_partial_matches(parameter, last, parser, contexts, display_options)
            )
        else
            error(string.format('Bug found. Item "%s" is unknown.', vim.inspect(recent_item)))
        end

        if parser:is_satisfied() then
            for parser_ in iterator_helper.iter_parsers(parser) do
                vim.list_extend(output, texter.get_array_startswith(parser_:get_names(), last_name))
            end
        end

        return output
    end

    local child_parser = matcher.get_exact_subparser_child(last_name, parser)

    if child_parser then
        -- NOTE: The last, parsed argument is a subparser. So we use it
        parser = child_parser
    end

    if not is_allowed_to_match_partial_results then
        local success = _validate_last_argument(last, parser, contexts)

        if not success then
            return {}
        end
    end

    if not child_parser then
        -- NOTE: If the last argument isn't a parser then it has to be
        -- a argument that matches a parameter. Find it and make sure
        -- that parameter calls `increment_used()`!
        --
        local next_index = index
        local argument_name = text_parse.get_argument_name(stripped.arguments[next_index])

        local found = evaluator.compute_and_increment_parameter(
            parser,
            argument_name,
            tabler.get_slice(stripped.arguments, next_index)
        )

        if not found then
            error("Bug found - This shouldn't be able to happen! Fix!", 0)
        end
    end

    local stripped_remainder = texter.lstrip(remainder)

    if parser:is_satisfied() then
        vim.list_extend(output, vim.fn.sort(matcher.get_matching_subparser_names("", parser)))
    end

    vim.list_extend(
        output,
        matcher.get_matching_position_parameters(stripped_remainder, parser:get_position_parameters(), contexts)
    )

    local prefix

    if texter.is_whitespace(remainder) then
        prefix = ""
    else
        prefix = text_parse.get_argument_name(last)
    end

    vim.list_extend(
        output,
        matcher.get_matching_partial_flag_text(
            prefix,
            parser:get_flag_parameters(),
            text_parse.get_argument_value_text(last),
            contexts,
            display_options
        )
    )

    return output
end

---@return cmdparse.Namespace # All default values from all (direct) child parameters.
function M.ParameterParser:_get_default_namespace()
    local output = {}

    for parameter in tabler.chain(self:get_position_parameters(), self:get_flag_parameters()) do
        if parameter.default then
            output[parameter:get_nice_name()] = parameter.default
        else
            local action = parameter:get_action_type()

            if action == constant.Action.store_true then
                output[parameter:get_nice_name()] = false
            elseif action == constant.Action.store_false then
                output[parameter:get_nice_name()] = true
            end
        end
    end

    return output
end

--- Search recursively for the lowest possible `cmdparse.ParameterParser` from `data`.
---
---@param data argparse.Results All of the arguments to consider.
---@return cmdparse.ParameterParser # The found parser, if any.
---
function M.ParameterParser:_get_leaf_parser(data)
    local parser = self
    --- @cast parser cmdparse.ParameterParser

    for index, argument in ipairs(data.arguments) do
        if argument.argument_type == argparse.ArgumentType.position then
            local argument_name = text_parse.get_argument_name(argument)

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

--- Make a `--help` parameter and add it to this current instance.
function M.ParameterParser:_add_help_parameter()
    local parameter = self:add_parameter({
        action = function(data)
            data.namespace.execute = function(...) -- luacheck: ignore 212 unused argument
                help_message.show_help(self:get_full_help(""))
            end
        end,
        help = "Show this help message and exit.",
        names = help_message.HELP_NAMES,
        nargs = 0,
    })

    -- NOTE: `self:add_parameter` just added the help flag to
    -- `self._flag_parameters` so we need to remove it (so we can add it
    -- somewhere else).
    --
    table.remove(self._flag_parameters)
    table.insert(self._implicit_flag_parameters, parameter)
end

--- Add `flags` to `namespace` if they match `argument`.
---
--- Raises:
---     If a flag is found and a value is expected but we fail to get a value for it.
---
---@param flags cmdparse.Parameter[]
---    All `-f`, `--foo`, `-f=ttt`, and `--foo=ttt`, parameters to check.
---@param arguments argparse.Argument[]
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

        return nargs == constant.Counter.one_or_more
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
    ---@param value_arguments argparse.Argument[]
    ---    All of the values that we think could be related to `flag`.
    ---@return (string[] | string)?
    ---    The found value, if any.
    ---
    local function _get_flag_values(flag, value_arguments)
        local nargs = flag:get_nargs()

        -- TODO: Need to handle expressions, probably

        if nargs == constant.Counter.one_or_more then
            local found_arguments = _get_next_position_arguments(value_arguments)

            if vim.tbl_isempty(found_arguments) then
                error(string.format('Parameter "%s" requires 1-or-more values. Got none.', flag.names[1]), 0)
            end

            return _get_position_argument_values(found_arguments)
        end

        if nargs == constant.Counter.zero_or_more then
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
                local template = 'Parameter "%s" requires "%s" values. Got "%s"'

                if values_count > 1 then
                    error(string.format(template .. " values.", flag.names[1], nargs, values_count), 0)
                else
                    error(string.format(template .. " value.", flag.names[1], nargs, values_count), 0)
                end
            end

            for index = 1, nargs do
                local argument = value_arguments[index]

                if
                    not argument
                    or argument.argument_type == argparse.ArgumentType.flag
                    or argument.argument_type == argparse.ArgumentType.named
                then
                    local template = 'Parameter "%s" requires "%s" values. Got "%s"'
                    local found_index = index - 1

                    if found_index == 1 then
                        template = template .. " value."
                    else
                        template = template .. " values."
                    end

                    error(string.format(template, flag.names[1], nargs, found_index), 0)
                end

                if index == nargs then
                    local arguments_ = tabler.get_slice(arguments, 1, nargs + 1)

                    return _get_position_argument_values(arguments_)
                end
            end

            -- NOTE: This code shouldn't be possible because conditions above
            -- should have covered all cases.
            --
            vlog.error("Unexpected code path found. This is probably a bug. Fix!")

            local arguments_ = tabler.get_slice(arguments, 1, nargs + 1)

            return _get_position_argument_values(arguments_)
        end
    end

    local function _validate_value_choices(flag, values, choices, argument_name)
        if choices == nil then
            local expected = flag.choices({
                contexts = vim.list_extend({ constant.ChoiceContext.error_message }, contexts),
                current_value = values,
            })

            error(
                string.format(
                    'Parameter "%s" got invalid "%s" value. Expected one of %s.',
                    flag.names[1],
                    values,
                    vim.inspect(vim.fn.sort(expected))
                ),
                0
            )
        end

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

            local current_value = values
            ---@cast current_value (string[] | string)?

            if flag.choices then
                local choices = flag.choices({
                    contexts = vim.list_extend({ constant.ChoiceContext.value_matching }, contexts),
                    current_value = current_value,
                })

                _validate_value_choices(flag, values, choices, argument.name)
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
---@param arguments argparse.Argument[]
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
---@return cmdparse.Parameter?
---    The matching parameter, if any.
---
function M.ParameterParser:_handle_exact_position_parameters(positions, arguments, namespace, contexts)
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

            if position.choices and vim.tbl_contains(contexts, constant.ChoiceContext.parsing) then
                local values_ = values

                if type(values) ~= "table" then
                    values_ = { values }
                end

                local current_value = values_[#values_]

                local choices = position.choices({
                    contexts = vim.list_extend({ constant.ChoiceContext.value_matching }, contexts),
                    current_value = current_value,
                })

                for _, value in ipairs(values_) do
                    if not vim.tbl_contains(choices, value) then
                        error(
                            string.format(
                                'Parameter "%s" got invalid "%s" value. Expected one of %s.',
                                position.names[1],
                                current_value,
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

            return true, total, position
        end
    end

    return false, 0, nil
end

--- Check if `argument_name` matches a registered subparser.
---
---@param data argparse.Results The parsed arguments + any remainder text.
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

--- Traverse the parsers, marking arguments as used / exhausted as we traverse down.
---
---@param data argparse.Results
---    User text that needs to be parsed.
---@return cmdparse.ParameterParser
---    The parser that was found in a current or previous iteration.
---@return cmdparse.ParameterParser | cmdparse.Parameter
---    The most recently parsed thing. Basically wherever we left off in the
---    parsing of `data`.
---@return number
---    A 1-or-more index value of the argument that we stopped parsing on.
---
function M.ParameterParser:_compute_matching_parsers(data, contexts)
    ---@return cmdparse.Parameter?
    ---@return number
    local function _seek_next_argument_from_flag(flag_parameters, arguments)
        local flag_argument = arguments[1]
        local other_arguments = tabler.get_slice(arguments, 2)

        for _, parameter in ipairs(flag_parameters) do
            if not parameter:is_exhausted() and vim.tbl_contains(parameter.names, flag_argument.name) then
                local nargs = parameter:get_nargs()

                if type(nargs) == "number" then
                    if nargs == 0 then
                        -- NOTE: We encountered a flag. We just accept this one
                        -- flag and move on.
                        --
                        return parameter, 1
                    end

                    for index = 1, nargs do
                        local argument = other_arguments[index]

                        if argument.argument_type ~= argparse.ArgumentType.position then
                            local found_index = index - 1
                            local template = 'Parameter "%s" requires "%s" values. Got "%s"'

                            if found_index == 1 then
                                template = template .. " value."
                            else
                                template = template .. " values."
                            end

                            error(string.format(template, parameter.names[1], nargs, found_index), 0)
                        end
                    end

                    return parameter, nargs
                elseif nargs == constant.Counter.zero_or_more then
                    local values_count = #other_arguments

                    for index = 1, values_count do
                        local argument = other_arguments[index]

                        if argument.argument_type ~= argparse.ArgumentType.position then
                            return parameter, index
                        end
                    end

                    return parameter, values_count
                elseif nargs == constant.Counter.one_or_more then
                    local values_count = #other_arguments
                    local found = false

                    for index = 1, values_count do
                        local argument = other_arguments[index]

                        if argument.argument_type ~= argparse.ArgumentType.position then
                            if not found then
                                error(
                                    string.format(
                                        'Parameter "%s" requires 1-or-more values. Got "%s" values.',
                                        text_parse.get_argument_name(argument),
                                        index - 1
                                    ),
                                    0
                                )
                            end

                            return parameter, index
                        end

                        found = true
                    end

                    return parameter, values_count
                end
            end
        end

        return nil, 0
    end

    local current_parser = self
    local count = #data.arguments

    contexts = contexts or {}

    -- NOTE: We search all but the last argument here.
    -- IMPORTANT: Every argument must have a match or it means the `arguments`
    -- failed to match something in the parser tree.
    --
    local index = 1
    local found = false
    ---@type cmdparse.ParameterParser | cmdparse.Parameter
    local current_item = self

    while index < count do
        local argument = data.arguments[index]
        local argument_name = text_parse.get_argument_name(argument)

        if argument.argument_type == argparse.ArgumentType.position then
            --- @cast argument argparse.PositionArgument

            for parser_ in iterator_helper.iter_parsers(current_parser) do
                if vim.tbl_contains(parser_:get_names(), argument_name) then
                    found = true
                    current_parser = parser_
                    current_item = current_parser

                    break
                end
            end

            if found then
                index = index + 1
            else
                -- TODO: Need to finish this part. It's not quite right because
                -- it doesn't take into account if a position is nargs=2
                -- / * / +
                --
                local position_parameters = current_parser:get_position_parameters()
                local arguments = tabler.get_slice(data.arguments, index)
                local used_arguments
                local found_parameter
                found, used_arguments, found_parameter =
                    current_parser:_handle_exact_position_parameters(position_parameters, arguments, {}, contexts)

                if not found then
                    if help_message.has_help(data.arguments) then
                        error(current_parser:get_full_help(data, current_parser), 0)
                    end

                    current_parser:_raise_suggested_positional_argument_fix(argument)
                end

                if found_parameter then
                    current_item = found_parameter
                end

                -- NOTE: We don't call increment_used() here because
                -- `_handle_exact_position_parameters` already does it for us.

                index = index + used_arguments
            end
        elseif argument.argument_type == argparse.ArgumentType.named then
            found = false
            local flag_parameters = current_parser:get_flag_parameters()

            for _, parameter in ipairs(flag_parameters) do
                if not parameter:is_exhausted() and vim.tbl_contains(parameter.names, argument.name) then
                    found = true
                    current_item = parameter

                    break
                end
            end

            if not found then
                vlog.fmt_error(
                    'Argument "%s" could not be parsed. Please check your spelling and try again.',
                    argument_name
                )

                return current_parser, current_item, index
            end

            ---@cast current_item cmdparse.Parameter
            current_item:increment_used()

            index = index + 1
        elseif argument.argument_type == argparse.ArgumentType.flag then
            ---@cast argument argparse.FlagArgument | argparse.NamedArgument

            local flag_parameters = current_parser:get_flag_parameters()
            local arguments = tabler.get_slice(data.arguments, index)
            local found_item
            local used_arguments
            found_item, used_arguments = _seek_next_argument_from_flag(flag_parameters, arguments)

            if not found_item then
                vlog.fmt_error(
                    'Argument "%s" could not be parsed. Please check your spelling and try again.',
                    argument_name
                )

                return current_parser, current_item, index
            end

            current_item = found_item
            current_item:increment_used()
            index = index + used_arguments
        end
    end

    -- NOTE: Because we completed the while loop without returning early, we
    -- assume that the loop fully completed so we return `count`. We can only
    -- do this because there is no `break` that terminates the while loop early.
    --
    return current_parser, current_item, count
end

--- Parse user text `data`.
---
--- Raises:
---    If we have to stop parsing midway because we found an unknown argument.
---
---@param data string | argparse.Results
---    User text that needs to be parsed. e.g. `hello "World!"`
---@param namespace cmdparse.Namespace
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

    local function _handle_position_argument(current_argument, data_, index, contexts)
        local arguments_to_consider = tabler.get_slice(data_.arguments, index)
        local position_parameters = self:get_position_parameters()
        local found, used_arguments =
            self:_handle_exact_position_parameters(position_parameters, arguments_to_consider, namespace, contexts)

        if not found then
            if help_message.has_help(data.arguments) then
                error(self:get_full_help(data), 0)
            end

            self:_raise_suggested_positional_argument_fix(current_argument)
        end

        return used_arguments
    end

    local function _handle_not_found(data_, index)
        -- NOTE: We lost our place in the parse so we can't continue.

        _validate_current_parser()

        local remaining_arguments = tabler.get_slice(data_.arguments, index)

        if #remaining_arguments == 1 then
            error(
                string.format('Unexpected argument "%s".', text_parse.get_arguments_raw_text(remaining_arguments)[1]),
                0
            )
        end

        error(
            string.format(
                'Unexpected arguments "%s".',
                vim.fn.join(text_parse.get_arguments_raw_text(remaining_arguments), ", ")
            ),
            0
        )
    end

    if type(data) == "string" then
        data = argparse.parse_arguments(data)
    end

    namespace = namespace or {}
    _merge_namespaces(namespace, self._defaults, self:_get_default_namespace())

    local flag_parameters = self:get_flag_parameters()
    local found = false
    local count = #data.arguments
    local index = 1

    local contexts = { constant.ChoiceContext.parsing }

    while index <= count do
        local argument = data.arguments[index]

        if argument.argument_type == argparse.ArgumentType.position then
            --- @cast argument argparse.PositionArgument
            local argument_name = text_parse.get_argument_name(argument)

            found = self:_handle_subparsers(argparse_helper.lstrip_arguments(data, index + 1), argument_name, namespace)

            if found then
                -- NOTE: We can only do this because `self:_handle_subparsers`
                -- calls `_parse_arguments` which creates a recursive loop.
                -- Once we finally terminate the loop and return here the
                -- `found` is the final status of all of those recursions.
                --
                return namespace
            end

            local used_arguments = _handle_position_argument(argument, data, index, contexts)
            found = used_arguments ~= 0
            index = index + used_arguments
        elseif
            argument.argument_type == argparse.ArgumentType.named
            or argument.argument_type == argparse.ArgumentType.flag
        then
            --- @cast argument argparse.FlagArgument | argparse.NamedArgument
            local arguments = tabler.get_slice(data.arguments, index)
            local used_arguments
            found, used_arguments = self:_handle_exact_flag_parameters(flag_parameters, arguments, namespace, contexts)

            if not found then
                error(vim.fn.join(self:_get_issues(), "\n"), 0)
            end

            index = index + used_arguments
        end

        if not found then
            _handle_not_found(data, index)
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

--- Tell the user how to solve the unparseable `argument`
---
--- Raises:
---     All issue(s) found, assuming 1+ issue was found.
---
---@param argument argparse.Argument
---    Some position / flag that we don't know what to do with.
---
function M.ParameterParser:_raise_suggested_positional_argument_fix(argument)
    local names = {}

    for _, parameter in ipairs(self:get_all_parameters()) do
        if parameter.required and not parameter:is_exhausted() then
            table.insert(names, parameter.names[1])
        end
    end

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
            'Got unexpected "%s" value. Did you mean this incomplete parameter? %s',
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

--- (Assuming parameter counts were modified by any function) Reset counts back to zero.
function M.ParameterParser:_reset_used()
    for _, parser in ipairs(_get_all_parsers(self)) do
        for parameter in tabler.chain(parser:get_position_parameters(), parser:get_flag_parameters()) do
            parameter._used = 0
        end

        for _, subparser in ipairs(self._subparsers) do
            subparser.visited = false
        end
    end
end

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
---@param data argparse.Results | string
---    The user input.
---@param column number?
---    A 1-or-more value that represents the user's cursor.
---@param options plugin_template.ConfigurationCmdparseAutoComplete?
---    The user settings to read from, if any. If no data is given, the user's
---    default configuration is used insteand.
---@return string[]
---    All found auto-complete options, if any.
---
function M.ParameterParser:get_completion(data, column, options)
    local success, result = pcall(function()
        local unsorted_output = self:_get_completion(data, column, options)
        local categories = sorter.categorize_arguments(unsorted_output)

        local output = {}

        vim.list_extend(output, vim.fn.sort(categories.positions))
        vim.list_extend(output, sorter.sort_and_flatten_flags(categories.flags))

        return output
    end)

    self:_reset_used()

    if success then
        return result
    end

    error(result, 0)
end

--- Get a 1-to-2 line summary on how to run the CLI.
---
---@param data string | argparse.Results
---    User text that needs to be parsed. e.g. `hello "World!"`
---    If `data` includes subparsers, that subparser's help message is returned instead.
---@return string
---    A one/two liner explanation of this instance's expected arguments.
---
function M.ParameterParser:get_concise_help(data)
    if type(data) == "string" then
        data = argparse.parse_arguments(data)
    end

    local summary, _ = self:_get_argument_usage_summary(data)

    return summary
end

--- Get all of information on how to run the CLI.
---
---@param data string | argparse.Results
---    User text that needs to be parsed. e.g. `hello "World!"`
---    If `data` includes subparsers, that subparser's help message is returned instead.
---@param parser cmdparse.ParameterParser?
---    The root parser to get a summary for. If no parser is given,
---    we auto-find it using `data`.
---@return string
---    The full explanation of this instance's expected arguments (can be pretty long).
---
function M.ParameterParser:get_full_help(data, parser)
    if type(data) == "string" then
        data = argparse.parse_arguments(data)
    end

    local summary
    summary, parser = self:_get_argument_usage_summary(data, parser)

    local output = { summary }
    vim.list_extend(output, help_message.get_parser_help_text_body(parser))

    return vim.fn.join(output, "\n\n") .. "\n"
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
        return self.choices({ contexts = { constant.ChoiceContext.parameter_names } })
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

---@return cmdparse.Subparsers # All immediate parser containers for this instance.
function M.ParameterParser:get_subparsers()
    return self._subparsers
end

--- Create a child parameter so we can use it to parse text later.
---
---@param options cmdparse.ParameterInputOptions
---    All of the settings to include in the new parameter.
---@return cmdparse.Parameter
---    The created `cmdparse.Parameter` instance.
---
function M.ParameterParser:add_parameter(options)
    types_input.expand_parameter_names(options)
    local is_position = text_parse.is_position_name(options.names[1])
    types_input.expand_parameter_options(options, is_position)

    --- @cast options cmdparse.ParameterOptions

    types_input.validate_parameter_options(options)

    local new_options = vim.tbl_deep_extend("force", options, { parent = self })
    local parameter = M.Parameter.new(new_options)

    if is_position then
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
---@param data string | argparse.Results
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

--- Re-parent this instance underneath `parser`.
---
---@param parser cmdparse.Subparsers The new parent to set.
---
function M.ParameterParser:set_parent(parser)
    self._parent = parser
end

return M
