--- Parse text into positional / named arguments.
---
--- @module 'plugin_template._cli.argparse2'
---

-- TODO: DOCSTRINGS
-- TODO: Clean-up code

-- TODO: Add unittest for required subparsers
-- - set_required must fail if subparsers has no dest

local argparse = require("plugin_template._cli.argparse")
local argparse_helper = require("plugin_template._cli.argparse_helper")
local tabler = require("plugin_template._core.tabler")
local texter = require("plugin_template._core.texter")

--- @alias argparse2.Action "append" | "count" | "store_false" | "store_true" | fun(data: argparse2.ActionData): nil
---     This controls the behavior of how parsed arguments are added into the
---     final parsed `argparse2.Namespace`.

--- @alias argparse2.Namespace table<string, any> All parsed values.

--- @alias argparse2.MultiNumber number | "*" | "+"
---     The number of elements needed to satisfy an argument. * == 0-or-more.
---     + == 1-or-more. A number means "we need exactly this number of
---     elements".

--- @class argparse2.ActionData
---     A struct of data that gets passed to an Argument's action.
--- @field name string
---     The argument name to set/append/etc some `value`.
--- @field namespace argparse2.Namespace
---     The container where parsed argument + value will go into. This
---     object gets directly modified when an action is called.
--- @field value any
---     A value to add into `namespace`.

--- @class argparse2.ArgumentOptions
---     All of the settings to include in a new parse argument.
--- @field action argparse2.Action?
---     This controls the behavior of how parsed arguments are added into the
---     final parsed `argparse2.Namespace`.
--- @field choices (fun(): string[])?
---     If included, the argument can only accept these choices as values.
--- @field count argparse2.MultiNumber
---     The number of times that this argument must be written.
--- @field description string?
---     Explain what this parser is meant to do and the argument(s) it needs.
---     Keep it brief (< 88 characters).
--- @field destination string?
---     When a parsed `argparse2.Namespace` is created, this field is used to store
---     the final parsed value(s). If no `destination` is given an
---     automatically assigned name is used instead.
--- @field name? string
---     The ways to refer to this instance.
--- @field names? string[]
---     The ways to refer to this instance.
--- @field nargs argparse2.MultiNumber
---     The number of elements that this argument consumes at once.
--- @field parent argparse2.ArgumentParser?
---     The parser that owns this instance.
--- @field type ("number" | "string" | fun(value: string): any)?
---     The expected output type. If a function is given, assume that the user
---     knows what they're doing and use their function's return value.

--- @class argparse2.ArgumentParserOptions
---     The options that we might pass to `argparse2.ArgumentParser.new`.
--- @field choices (fun(): string[])?
---     If included, the argument can only accept these choices as values.
--- @field description string
---     Explain what this parser is meant to do and the argument(s) it needs.
---     Keep it brief (< 88 characters).
--- @field name string?
---     The parser name. This only needed if this parser has a parent subparser.
--- @field parent argparse2.Subparsers?
---     A subparser that own this `argparse2.ArgumentParser`, if any.

--- @class argparse2.SubparsersOptions
---     Customization options for the new argparse2.Subparsers.
--- @field description string
---     Explain what types of parsers this object is meant to hold Keep it
---     brief (< 88 characters).
--- @field destination string
---     An internal name to track this subparser group.

--- @class argparse2.Subparsers A group of parsers.

local M = {}

-- TODO: Add support for this later
local _ONE_OR_MORE = "+"
local _ZERO_OR_MORE = "*"

local _FULL_HELP_FLAG = "--help"
local _SHORT_HELP_FLAG = "-h"

--- @class argparse2.Argument
---     An optional / required argument for some parser.
--- @field action argparse2.Action?
---     This controls the behavior of how parsed arguments are added into the
---     final parsed `argparse2.Namespace`.
--- @field destination string?
---     When a parsed `argparse2.Namespace` is created, this field is used to store
---     the final parsed value(s). If no `destination` is given an
---     automatically assigned name is used instead.
---
M.Argument = {
    __tostring = function(argument)
        return string.format(
            "argparse2.Argument({names=%s, help=%s, type=%s, action=%s, nargs=%s, choices=%s, count=%s, used=%s})",
            vim.inspect(argument.names),
            vim.inspect(argument.help),
            vim.inspect(argument.type),
            vim.inspect(argument._action),
            vim.inspect(argument._nargs),
            vim.inspect(argument.choices),
            vim.inspect(argument._count),
            vim.inspect(argument._used)
        )
    end,
}
M.Argument.__index = M.Argument

--- @class argparse2.ArgumentParser
---     A starting point for arguments (positional arguments, flag arguments, etc).
--- @field choices (fun(): string[])?
---     If included, this parser can be referred to using these names instead of its expected name.
--- @field description string
---     Explain what this parser is meant to do and the argument(s) it needs.
---     Keep it brief (< 88 characters).
--- @field name string?
---     The parser name. This only needed if this parser has a parent subparser.
---
M.ArgumentParser = {
    __tostring = function(parser)
        return string.format(
            'argparse2.ArgumentParser({name="%s", description="%s", choices=%s})',
            parser.name,
            parser.description,
            parser.choices
        )
    end,
}
M.ArgumentParser.__index = M.ArgumentParser

M.Subparsers = {
    __tostring = function(subparsers)
        return string.format(
            'argparse2.Subparsers({description="%s", destination="%s"})',
            subparsers.description,
            subparsers.destination
        )
    end,
}
M.Subparsers.__index = M.Subparsers

--- Check if `text`.
---
--- @param text string Some text. e.g. `--foo`.
--- @return boolean # If `text` is a word, return `true.
---
local function _is_position_name(text)
    return text:sub(1, 1):match("%w")
end

--- Check if `text` is only spaces.
---
--- @param text string Some word / phrase to check. e.g. `" "`.
--- @return boolean # If `text` has non-empty alphanumeric character(s), return `true`.
---
local function _is_whitespace(text)
    return text == "" or text:match("%s+")
end

--- Find all parsers / sub-parsers starting from `parsers`.
---
--- @param parsers argparse2.ArgumentParser[] All child / leaf parsers to start traversing from.
---
local function _get_all_parent_parsers(parsers)
    local output = {}

    for _, parser in ipairs(parsers) do
        --- @type argparse2.ArgumentParser | argparse2.Subparsers
        local current = parser

        while current do
            table.insert(output, current)
            current = parser._parent
        end
    end

    return output
end

--- Get the raw argument name. e.g. `"--foo"`.
---
--- Important:
---     If `argument` is a flag, this function must return back the prefix character(s) too.
---
--- @param argument argparse.ArgparseArgument Some named argument to get text from.
--- @return string # The found name.
---
local function _get_argument_name(argument)
    return argument.name or argument.value
end

--- Get the recommended name(s) of all `arguments`.
---
--- @param arguments argparse2.Argument[] All flag / position arguments to get names for.
--- @return string[] # The found names.
---
local function _get_arguments_names(arguments)
    return vim:iter(arguments)
        :map(function(argument)
            return argument.names[1]
        end)
        :totable()
end

local function _get_array_startswith(values, prefix)
    local output = {}

    for _, value in ipairs(values) do
        if vim.startswith(value, prefix) then
            table.insert(output, value)
        end
    end

    return output
end

local function _remove_boundary_whitespace(text)
    return (text:gsub("^%s*$", ""))
end

--- Re-order `arguments` alphabetically but put the `--help` flag at the end.
---
--- @param arguments argparse2.Argument[] All position / flag / named arguments.
--- @return argparse2.Argument[] # The sorted entries.
---
local function _sort_arguments(arguments)
    local output = vim.deepcopy(arguments)

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

--- Scan `input` and stop processing arguments after `column`.
---
--- @param input argparse.ArgparseResults
---     The user's parsed text.
--- @param column number
---     The point to stop checking for arguments. Must be a 1-or-greater value.
--- @return number
---     The found index. If all arguments are < `column` then the returning
---     index will cover all of `input.arguments`.
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

local function _get_matching_partial_flag_text(prefix, flags, value)
    local function _get_single_choices_text(argument, value)
        if not argument.choices then
            return { argument.names[1] .. "=" }
        end

        value = value or ""

        local output = {}

        for _, choice in ipairs(argument.choices()) do
            if vim.startswith(choice, value) then
                table.insert(output, argument.names[1] .. "=" .. choice)
            end
        end

        return output
    end

    local output = {}

    for _, argument_ in ipairs(_sort_arguments(flags)) do
        if not argument_:is_exhausted() then
            for _, name in ipairs(argument_.names) do
                if name == prefix then
                    if argument_:get_nargs() == 1 then
                        vim.list_extend(output, _get_single_choices_text(argument_, value))
                    else
                        table.insert(output, name)
                    end
                elseif vim.startswith(name, prefix) then
                    if argument_:get_nargs() == 1 then
                        table.insert(output, name .. "=")
                    else
                        table.insert(output, name)
                    end
                end
                -- if vim.startswith(name, prefix) then
                --     if argument_.choices then
                --         for _, choice in ipairs(argument_.choices()) do
                --             if argument_:get_nargs() == 1 then
                --                 table.insert(output, argument_.names[1] .. "=" .. choice)
                --             else
                --                 table.insert(output, choice)
                --             end
                --         end
                --     else
                --         if argument_:get_nargs() == 1 then
                --             table.insert(output, argument_.names[1] .. "=")
                --         else
                --             table.insert(output, argument_.names[1])
                --         end
                --     end
                --
                --     break
                -- end
            end
        end
    end

    return output
end

local function _get_matching_position_arguments(name, arguments)
    local output = {}

    for _, argument in ipairs(_sort_arguments(arguments)) do
        if not argument:is_exhausted() and argument.choices then
            vim.list_extend(output, _get_array_startswith(argument.choices(), name))
        end
    end

    return output
end

--- Find all direct-children parsers of `parser`.
---
--- Note:
---     This is not recursive. It just gets the direct children.
---
--- @param parser argparse2.ArgumentParser
---     The starting point ot saerch for child parsers.
--- @param inclusive boolean?
---     If `true`, `parser` will be the first returned value. If `false` then
---     only the children are returned.
--- @return fun(): argparse2.ArgumentParser?
---     An iterator that find all child parsers.
---
local function _iter_parsers(parser, inclusive)
    -- TODO: Audit this variable. Maybe remove / make default
    if inclusive == nil then
        inclusive = false
    end

    local subparsers_index = 1
    local subparsers = parser._subparsers[subparsers_index]
    local returned_parser = false

    -- TODO: Remove?
    -- if not subparsers then
    --     if inclusive then
    --         return function() return nil end
    --     end
    --
    --     return function()
    --         if not returned_parser then
    --             returned_parser = true
    --
    --             return parser
    --         end
    --
    --         return nil
    --     end
    -- end

    local parser_index = 1
    local parsers = {}

    if subparsers then
        parsers = subparsers:get_parsers()
    end

    local parser_count = #parsers

    return function()
        if inclusive and not returned_parser then
            return parser
        end

        if parser_index > parser_count then
            -- NOTE: Get the next subparsers.
            parser_index = 1
            subparsers_index = subparsers_index + 1
            parsers = parser._subparsers[subparsers_index]

            if not parsers then
                -- NOTE: We reached the end.
                return nil
            end

            return parsers[parser_index]
        end

        local result = parsers[parser_index]

        parser_index = parser_index + 1

        return result
    end
end

-- TODO: Docstring
--- Find all Argments starting with `name`.
---
--- @param parser argparse2.ArgumentParser The starting point to search within.
--- @return string[] # The matching names, if any.
---
local function _get_exact_or_partial_matches(prefix, parser, value)
    prefix = _remove_boundary_whitespace(prefix)
    local output = {}

    vim.list_extend(output, _get_matching_position_arguments(prefix, parser:get_position_arguments()))

    vim.list_extend(output, _get_matching_partial_flag_text(prefix, parser:get_flag_arguments(), value))

    -- print(vim.inspect(parsers, {depth=2}))

    -- for _, parser in ipairs(parsers) do
    --     for parser_ in _iter_parsers(parser) do
    --         print(parser_)
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

-- local function _get_matching_position_arguments(argument, parser)
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

--- Combine `labels` into a single-line summary (for help messages).
---
--- @param labels string[] All commands to run.
--- @return string # The created text.
---
local function _get_help_command_labels(labels)
    return string.format("{%s}", vim.fn.join(vim.fn.sort(labels), ", "))
end

--- Find all required arguments in `parser` that still need value(s).
---
--- @param parsers argparse2.ArgumentParser[] All child / leaf parsers to check.
--- @return argparse2.Argument[] # The arguments that are still unused.
---
local function _get_incomplete_arguments(parsers)
    local output = {}

    for _, parser in ipairs(_get_all_parent_parsers(parsers)) do
        for _, argument in ipairs(parser:get_all_arguments()) do
            if argument.required and not argument:is_exhausted() then
                table.insert(output, argument)
            end
        end
    end

    return output
end

--- Find all all child parsers that start with `prefix`, starting from `parser`.
---
--- This function is *exclusive* - `parser` cannot be returned from this function.
---
--- @param prefix string Some text to search for.
--- @param parser argparse2.ArgumentParser The starting point to search within.
--- @return string[] # The names of all matching child parsers.
---
local function _get_matching_subparser_names(prefix, parser)
    local output = {}

    for parser_ in _iter_parsers(parser) do
        local names = parser_:get_names()

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
--- @param text string Some raw argument name. e.g. `"--foo"`.
--- @return string # The (clean) argument mame. e.g. `"foo"`.
---
local function _get_nice_name(text)
    return text:match("%W*(%w+)")
end

--- Find the next arguments that need to be completed / used based on some partial `remainder_text`.
---
--- @param argument argparse.ArgparseArgument
---     The last known argument (which we will use to find the next argument(s)).
--- @param remainder_text string
---     Text that we tried to parse into a valid argument but couldn't. Usually
---     this is empty or is just whitespace.
--- @param parsers argparse2.ArgumentParser[]
---     Any subparsers that we need to consider for the next argument(s).
--- @return string[]
---     The matching names, if any.
---
local function _get_next_arguments_from_remainder(argument, remainder_text, parsers)
    -- local name = _get_argument_name(argument)
    -- local matches = vim.iter(parsers):filter(function(parser)
    --     return vim.tbl_contains(parser:get_names(), name)
    -- end):totable()
    -- -- TODO: If 2+ matches, log a warning
    -- local match = matches[1]

    local output = {}

    local match = parsers[#parsers]

    -- TODO: Fix the argument4 sorting here. It's broken
    -- See "dynamic argument - works with positional arguments" test
    --
    if match then
        vim.list_extend(output, vim.fn.sort(_get_matching_subparser_names(remainder_text, match)))
    end

    vim.list_extend(output, _get_exact_or_partial_matches(remainder_text, match))

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
-- --- @param parser argparse2.ArgumentParser The starting point to search within.
-- --- @return string[] # The matching names, if any.
-- ---
-- local function _get_next_exact_or_partial_arguments(parser)
--     local output = {}
--     vim.list_extend(output, vim.fn.sort(_get_matching_subparser_names(parser)))
--     vim.list_extend(output, _get_exact_or_partial_matches(parser))
--
--     return output
-- end

--- Get a friendly label for `position`. Used for `--help` flags.
---
--- If `position` has expected choices, those choices are returned instead.
---
--- @param position argparse2.Argument Some (non-flag) argument to get text for.
--- @return string # The found label.
---
local function _get_position_help_text(position)
    local text = ""

    if position.choices then
        text = _get_help_command_labels(position.choices())
    else
        text = position:get_nice_name()
    end

    if position.description then
        text = text .. "    " .. position.description
    end

    return text
end

--- Add indentation to `text.
---
--- @param text string Some phrase to indent one level. e.g. `"foo"`.
--- @return string # The indented text, `"    foo"`.
---
local function _indent(text)
    return string.format("    %s", text)
end

--- Get all option flag / named argument --help text from `parser`.
---
--- @param parser argparse2.ArgumentParser Some runnable command to get arguments from.
--- @return string[] # The labels of all of the flags.
---
local function _get_parser_flag_help_text(parser)
    local output = {}

    for _, flag in ipairs(_sort_arguments(parser:get_flag_arguments())) do
        local names = vim.fn.join(flag.names, " ")
        local text = ""

        if flag.description then
            text = string.format("%s    %s", names, flag.description)
        else
            text = names
        end

        table.insert(output, _indent(text))
    end

    if not vim.tbl_isempty(output) then
        table.insert(output, 1, "Options:")
    end

    return output
end

--- Get all position argument --help text from `parser`.
---
--- @param parser argparse2.ArgumentParser Some runnable command to get arguments from.
--- @return string[] # The labels of all of the flags.
---
local function _get_parser_position_help_text(parser)
    local output = {}

    for _, position in ipairs(parser:get_position_arguments()) do
        local text = _get_position_help_text(position)

        table.insert(output, _indent(text))
    end

    for parser_ in _iter_parsers(parser) do
        local names = parser_:get_names()
        local text = names[1]

        if #names ~= 1 then
            text = _get_help_command_labels(names)
        end

        if parser_.description then
            text = text .. "    " .. parser_.description
        end

        table.insert(output, _indent(text))
    end

    output = vim.fn.sort(output)

    if not vim.tbl_isempty(output) then
        table.insert(output, 1, "Positional Arguments:")
    end

    return output
end

--- Get the name(s) used to refer to `parsers`.
---
--- Usually a parser can only be referred to by one name, in which case this
--- function returns one string for every parser in `parsers`. But sometimes
--- parsers can be referred to by several names. If that happens then the
--- output string will have more elements than `parsers`.
---
--- @param parsers argparse2.ArgumentParser[] The parsers to get names from.
--- @return string[] # All ways to refer to `parsers`.
---
local function _get_parsers_names(parsers)
    local output = {}

    for _, parser in ipairs(parsers) do
        vim.list_extend(parser:get_names())
    end

    return output
end

--- Find all required child parsers from `parsers`.
---
--- @param parsers argparse2.ArgumentParser[] Each parser to search within.
--- @return argparse2.ArgumentParser[] # The found required child parsers, if any.
---
local function _get_unused_required_subparsers(parsers)
    local output = {}

    for _, parser in ipairs(parsers) do
        for _, subparser in ipairs(parser._subparsers) do
            if subparser.required then
                vim.list_extend(output, subparser:get_parsers())
            end
        end
    end

    return output
end

--- Print `data` but don't recurse.
---
--- If you don't call this function and you try to print one of our Argument
--- types, it will print parent / child objects and it ends up priting the
--- whole tree. This function instead prints just the relevant details.
---
--- @param data any Anything. Usually an Argument type from this file.
--- @return string # The found data.
---
local function _concise_inspect(data)
    return vim.inspect(data, { depth = 1 })
end

--- Find a proper type converter from `options`.
---
--- @param options argparse2.ArgumentOptions The suggested type for an argument.
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
    else
        error(string.format('Type "%s" is unknown. We can\'t parse it.', _concise_inspect(options)))
    end
end

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
    elseif texter.is_string_list(options.choices) then
        choices = function()
            return input
        end
    elseif type(options.choices) == "function" then
        choices = input
    else
        error(
            string.format('Got invalid "%s" choices. Expected a list or a function.', _concise_inspect(options.choices))
        )
    end

    options.choices = choices
end

--- If `options` is sparsely written, "expand" all of its values. so we can use it.
---
--- @param options argparse2.ArgumentOptions The user-written options. (sparse or not).
---
local function _expand_argument_options(options)
    _expand_type_options(options)
    _expand_choices_options(options)
end

local function _merge_namespaces(namespace, ...)
    for _, override in ipairs({ ... }) do
        for key, value in pairs(override) do
            namespace[key] = value
        end
    end
end

--- Remove the ending `index` options from `input`.
---
--- @param input argparse.ArgparseResults
---     The parsed arguments + any remainder text.
--- @param column number
---     The found index. If all arguments are < `column` then the returning
---     index will cover all of `input.arguments`.
--- @return argparse.ArgparseResults
---     The stripped copy from `input`.
---
local function _rstrip_input(input, column)
    local stripped = argparse_helper.rstrip_arguments(input, _get_cursor_offset(input, column))

    local last = stripped.arguments[#stripped.arguments]

    if last then
        stripped.remainder.value = input.text:sub(last.range.end_column + 1, #input.text)
    else
        stripped.remainder.value = input.text:sub(1, column)
    end

    stripped.text = input.text:sub(1, column)

    return stripped
end

-- TODO: Add unittest for this
--- Make sure an `argparse2.Argument` has a name and every name is the same type.
---
--- If `names` is `{"foo", "-f"}` then this function will error.
---
--- @param options argparse2.ArgumentOptions All data to check.
---
local function _validate_argument_names(options)
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
                    "Argument names have to be the same type. "
                        .. 'e.g. If one name starts with "-", all names '
                        .. 'must start with "-" and vice versa.'
                )
            )
        end
    end

    if not found_type then
        error('Options "%s" must provide at least one name.', vim.inspect(names))
    end

    options.names = names
end

--- Make sure a name was provided from `options`.
---
--- @param options argparse2.ArgumentParserOptions
---
local function _validate_name(options)
    -- TODO: name is required
    if not options.name or _is_whitespace(options.name) then
        error(string.format('Argument "%s" must have a name.', _concise_inspect(options)))
    end
end

--- Create a new group of parsers.
---
--- @param options argparse2.SubparsersOptions Customization options for the new argparse2.Subparsers.
--- @return argparse2.Subparsers # A group of parsers (which will be filled with parsers later).
---
function M.Subparsers.new(options)
    local self = setmetatable({}, M.Subparsers)

    self.description = options.description
    self.destination = options.destination
    self._parent = options.parent
    self._parsers = {}

    return self
end

--- Create a new `argparse2.ArgumentParser` using `options`.
---
--- @param options argparse2.ArgumentParserOptions The options to pass to `argparse2.ArgumentParser.new`.
--- @return argparse2.ArgumentParser # The created parser.
---
function M.Subparsers:add_parser(options)
    local new_options = vim.tbl_deep_extend("force", options, { parent = self })
    local parser = M.ArgumentParser.new(new_options)

    table.insert(self._parsers, parser)

    return parser
end

--- @return argparse2.ArgumentParser[] # Get all of the child parsers for this instance.
function M.Subparsers:get_parsers()
    return self._parsers
end

--- Create a new instance using `options`.
---
--- @param options argparse2.ArgumentOptions All of the settings to include in a new parse argument.
--- @return argparse2.Argument # The created instance.
---
function M.Argument.new(options)
    --- @class argparse2.Argument
    local self = setmetatable({}, M.Argument)

    self._action = nil
    self._count = options.count or 1
    self._nargs = options.nargs or 1
    self._type = options.type
    self._used = 0
    self.choices = options.choices
    self.default = options.default
    self.names = options.names
    self.description = options.description
    self.destination = _get_nice_name(options.destination or options.names[1])
    self:set_action(options.action)
    self._parent = options.parent

    return self
end

--- @return boolean # Check if this instance cannot be used anymore.
function M.Argument:is_exhausted()
    if self._count == _ZERO_OR_MORE then
        return false
    end

    -- TODO: Consider 1-or-more here, too

    return self._used >= self._count
end

--- Get a function that mutates the namespace with a new parsed argument.
---
--- @return fun(data: argparse2.ActionData): nil
---     A function that directly modifies the contents of `data`.
---
function M.Argument:get_action()
    return self._action
end

--- @return argparse2.MultiNumber # The number of elements that this argument consumes at once.
function M.Argument:get_nargs()
    return self._nargs
end

--- @return string # The (clean) argument mame. e.g. `"--foo"` becomes `"foo"`.
function M.Argument:get_nice_name()
    return _get_nice_name(self.destination or self.names[1])
end

--- @return string # The (raw) argument mame. e.g. `"--foo"`.
function M.Argument:get_raw_name()
    return self.names[1]
end

--- Get a converter function that takes in a raw argument's text and outputs some converted result.
---
--- @return fun(value: (string | boolean)?): any # The converter function.
---
function M.Argument:get_type()
    return self._type
end

--- Use up more of the available use(s) of this instance.
---
--- Most arguments can only be used one time but some can be used multiple
--- times. This function takes up at least one of these available uses.
---
--- @param increment number? The number of uses to consume.
---
function M.Argument:increment_used(increment)
    increment = increment or 1
    self._used = self._used + increment
end

--- Describe how this argument should ingest new CLI value(s).
---
--- @param action argparse2.Action The selected functionality.
---
function M.Argument:set_action(action)
    if action == "store_false" then
        action = function(data)
            data.namespace[data.name] = false
        end
    elseif action == "store_true" then
        action = function(data)
            data.namespace[data.name] = true
        end
    elseif action == "count" then
        action = function(data)
            local name = data.name
            local namespace = data.namespace

            if not namespace[name] then
                namespace[name] = 0
            end

            namespace[name] = namespace[name] + 1
        end
    elseif action == "append" then
        action = function(data)
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
--- @param count string | number
---     The number of values we need for this instance. `"*"` ==  0-or-more,
---     `"+"` == 1-or-more. A number means there needs to exactly that many
---     arguments (no less no more).
---
function M.Argument:set_nargs(count)
    if count == "*" then
        count = _ZERO_OR_MORE
    elseif count == "+" then
        count = _ONE_OR_MORE
    end

    self._nargs = count
end

--- Create a new `argparse2.ArgumentParser`.
---
--- If the parser is a child of a subparser then this instance must be given
--- a name via `{name="foo"}` or this function will error.
---
--- @param options argparse2.ArgumentParserOptions
---     The options that we might pass to `argparse2.ArgumentParser.new`.
--- @return argparse2.ArgumentParser
---     The created instance.
---
function M.ArgumentParser.new(options)
    if options[1] and not options.name then
        options.name = options[1]
    end

    if options.parent then
        _validate_name(options)
    end

    _expand_choices_options(options)

    --- @class argparse2.ArgumentParser
    local self = setmetatable({}, M.ArgumentParser)

    self.name = options.name
    self.choices = options.choices
    self.description = options.description
    self._defaults = {}
    self._position_arguments = {}
    self._flag_arguments = {}
    self._subparsers = {}
    self._parent = options.parent

    self:add_argument({
        action = "store_true",
        description = "Show this help message and exit.",
        names = { "--help", "-h" },
        nargs = 0,
    })

    return self
end

--- Get auto-complete options based on this instance + the user's `data` input.
---
--- @param data argparse.ArgparseResults | string The user input.
--- @param column number? A 1-or-more value that represents the user's cursor.
--- @return string[] # All found auto-complete options, if any.
---
function M.ArgumentParser:_get_completion(data, column)
    if type(data) == "string" then
        data = argparse.parse_arguments(data)
    end

    self:_reset_used()

    column = column or #data.text
    local stripped = _rstrip_input(data, column)
    local remainder = stripped.remainder.value
    local output = {}

    if vim.tbl_isempty(stripped.arguments) then
        if not _is_whitespace(remainder) then
            -- NOTE: If there was unparsed text then it means that the user is
            -- in the middle of an argument. We don't waot to show completion
            -- options in that situation.
            --
            return {}
        end

        -- NOTE: Get all possible initial arguments
        vim.list_extend(output, vim.fn.sort(_get_matching_subparser_names("", self)))
        vim.list_extend(output, _get_matching_position_arguments("", self:get_position_arguments()))
        vim.list_extend(output, _get_matching_partial_flag_text("", self:get_flag_arguments()))

        return output
    end

    local parsers, previous_parser = self:_compute_matching_parsers(stripped.arguments)

    if remainder ~= "" then
        -- if not parsers then
        --     -- NOTE: Something went wrong during parsing. We don't know where
        --     -- the user is in the tree so we need to exit early.
        --     --
        --     -- TODO: Check if this situation actually happens in the unittests.
        --     -- If so, add a log.
        --     --
        --     return {}
        -- end

        local last = stripped.arguments[#stripped.arguments]

        return _get_next_arguments_from_remainder(last, remainder, parsers or { previous_parser })
    end

    local last = stripped.arguments[#stripped.arguments]
    local last_name = _get_argument_name(last)

    -- TODO: Make this all into a function. Simplify the code
    if not parsers and previous_parser then
        vim.list_extend(output, _get_exact_or_partial_matches(last_name, previous_parser))

        if not _is_whitespace(last_name) then
            for parser_ in _iter_parsers(previous_parser) do
                vim.list_extend(output, _get_array_startswith(parser_:get_names(), last_name))
            end
        end
    end
    for _, parser in ipairs(parsers or {}) do
        vim.list_extend(output, _get_exact_or_partial_matches(last_name, parser, last.value))

        -- TODO: Move to a function later
        -- NOTE: This case is for when there are multiple child parsers with
        -- similar names. e.g. `get-asset` & `get-assets` might both auto-complete here.
        --
        local parent_parser = parser:get_parent_parser()
        if parent_parser and not _is_whitespace(last_name) then
            for parser_ in _iter_parsers(parent_parser) do
                vim.list_extend(output, _get_array_startswith(parser_:get_names(), last_name))
            end
        end
    end

    output = vim.fn.sort(output)

    -- local remainder = stripped.remainder.value
    --
    -- local output = {}
    --
    -- local last = stripped.arguments[#stripped.arguments]
    -- local last_name = _get_argument_name(last)

    -- if remainder == "" then
    --     -- TODO: There's a bug here. We may not be able to assume the last argument like this
    --     local last = stripped.arguments[#stripped.arguments]
    --     local last_name = _get_argument_name(last)
    --     output = _get_matching_position_arguments(last_name, parser)
    --     output = vim.fn.sort(output)
    --
    --     return output
    -- end
    --
    -- vim.list_extend(output, vim.fn.sort(_get_matching_subparser_names(parser, remainder)))
    --
    -- for argument in tabler.chain(_sort_arguments(parser._flag_arguments)) do
    --     table.insert(output, argument:get_raw_name())
    -- end

    return output
end

--- @return argparse2.Namespace # All default values from all (direct) child arguments.
function M.ArgumentParser:_get_default_namespace()
    local output = {}

    -- TODO: Add unittests for these arg types
    for argument in tabler.chain(self:get_position_arguments(), self:get_flag_arguments()) do
        if argument.default then
            output[argument:get_nice_name()] = argument.default
        end
    end

    return output
end

-- TODO: Consider merging this code with the over traversal code
--- Search recursively for the lowest possible `argparse2.ArgumentParser` from `data`.
---
--- @param data argparse.ArgparseResults All of the arguments to consider.
--- @return argparse2.ArgumentParser # The found parser, if any.
---
function M.ArgumentParser:_get_leaf_parser(data)
    local parser = self
    --- @cast parser argparse2.ArgumentParser

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

--- @return string # A one/two liner explanation of this instance's expected arguments.
function M.ArgumentParser._get_usage_summary(parser)
    local text = {}

    for _, position in ipairs(parser:get_position_arguments()) do
        table.insert(text, _get_position_help_text(position))
    end

    for _, flag in ipairs(_sort_arguments(parser:get_flag_arguments())) do
        table.insert(text, string.format("[%s]", flag:get_raw_name()))
    end

    -- TODO: Need to finish the concise args and also give advice on the next line
    return string.format("Usage: %s", vim.fn.join(text, " "))
end

--- Add `flags` to `namespace` if they match `argument`.
---
--- @param flags argparse2.Argument[] All `-f=asdf`, `--foo=asdf`, etc arguments to check.
--- @param argument argparse.FlagArgument | argparse.NamedArgument The argument to check for `flags` matches.
--- @param namespace argparse2.Namespace # A container for the found match(es).
--- @return boolean # If a match was found, return `true`.
---
function M.ArgumentParser:_handle_exact_flag_arguments(flags, argument, namespace)
    for _, flag in ipairs(flags) do
        if vim.tbl_contains(flag.names, argument.name) and not flag:is_exhausted() then
            local name = flag:get_nice_name()

            local value

            -- TODO: Replace this with a real nargs check later
            if argument.value then
                value = flag:get_type()(argument.value)
            else
                value = flag:get_type()()
            end

            local action = flag:get_action()

            action({ namespace = namespace, name = name, value = value })

            -- TODO: Possible bug here. What if the `flag` has explicit
            -- choice(s) and the written value doesn't match it? I guess in
            -- that case the flag shouldn't be incremented?
            --
            flag:increment_used()

            return true
        end
    end

    return false
end

--- Add `positions` to `namespace` if they match `argument`.
---
--- @param positions argparse2.Argument[] All `foo`, `bar`, etc arguments to check.
--- @param argument argparse.ArgparseArgument The argument to check for `positions` matches.
--- @param namespace argparse2.Namespace # A container for the found match(es).
--- @return boolean # If a match was found, return `true`.
---
function M.ArgumentParser:_handle_exact_position_arguments(positions, argument, namespace)
    for _, position in ipairs(positions) do
        if not position:is_exhausted() then
            local name = position:get_nice_name()
            local value = position:get_type()(argument.value)
            local action = position:get_action()

            action({ namespace = namespace, name = name, value = value })

            position:increment_used()

            return true
        end
    end

    return false
end

--- Check if `argument_name` matches a registered subparser.
---
--- @param data argparse.ArgparseResults The parsed arguments + any remainder text.
--- @param argument_name string A raw argument name. e.g. `foo`.
--- @param namespace argparse2.Namespace An existing namespace to set/append/etc to the subparser.
--- @return boolean # If a match was found, return `true`.
--- @return argparse2.ArgumentParser? # The found subparser, if any.
---
function M.ArgumentParser:_handle_subparsers(data, argument_name, namespace)
    for parser in _iter_parsers(self) do
        if vim.tbl_contains(parser:get_names(), argument_name) then
            parser:_parse_arguments(data, namespace)

            return true, parser
        end
    end

    return false, nil
end

-- TODO: Consider returning just 1 parser, not a list
--- Traverse the parsers, marking arguments as used / exhausted as we traverse down.
---
--- @param arguments argparse.ArgparseArgument[]
---     All user inputs to walk through.
--- @return argparse2.ArgumentParser[]?
---     All matching parsers, if any. If we failed to walk the `arguments`
---     completely, we return nothing to indicate a failure.
---
function M.ArgumentParser:_compute_matching_parsers(arguments)
    local function _is_single_nargs_and_named_argument(argument, arguments)
        if argument:get_nargs() ~= 1 then
            return false
        end

        local argument_ = arguments[1]

        if not argument_ then
            return false
        end

        if argument_.argument_type ~= argparse.ArgumentType.named then
            return false
        end

        if argument.choices then
            return vim.tbl_contains(argument.choices(), argument_.value)
        end

        return vim.tbl_contains(argument.names, argument_.name)
    end

    local function _has_position_argument_match(name, argument)
        if not argument.choices then
            -- NOTE: Any value is valid if there are no explicit choices
            return true
        end

        if vim.tbl_contains(argument.choices(), name) then
            return true
        end

        return false
    end

    local function _has_satisfying_value(argument, arguments)
        if _is_single_nargs_and_named_argument(argument, arguments) then
            return true
        end

        local nargs = argument:get_nargs()

        if nargs == 0 or nargs == _ZERO_OR_MORE then
            -- NOTE: If `argument` doesn't need any value then it is definitely satisified.
            return true
        end

        local count = 0

        for _, argument_ in ipairs(arguments) do
            if argument_.argument_type ~= argparse.ArgumentType.position then
                -- NOTE: Flag arguments can only accept non-flag arguments, in general.
                return false
            end

            count = count + 1

            if count == nargs or nargs == _ONE_OR_MORE then
                return true
            end
        end

        -- NOTE: There wasn't enough `arguments` left to satisfy `argument`.
        return false
    end

    local function _compute_exact_flag_match(argument_name, parser, arguments)
        for _, argument_ in ipairs(parser:get_flag_arguments()) do
            if
                not argument_:is_exhausted()
                and vim.tbl_contains(argument_.names, argument_name)
                and _has_satisfying_value(argument_, arguments)
            then
                argument_:increment_used()

                return true
            end
        end

        return false
    end

    local function _compute_exact_position_match(argument_name, parser)
        for _, argument_ in ipairs(parser:get_position_arguments()) do
            if not argument_:is_exhausted() then
                if _has_position_argument_match(argument_name, argument_) then
                    -- TODO: Handle this scenario. Need to do nargs checks and stuff
                    argument_:increment_used()

                    return true
                end
            end
        end

        return false
    end

    local previous_parser = nil
    local current_parser = self
    local count = #arguments

    -- NOTE: We search all but the last argument here.
    -- IMPORTANT: Every argument must have a match or it means the `arguments`
    -- failed to match something in the parser tree.
    --
    for index = 1, count do
        local argument = arguments[index]
        local argument_name = _get_argument_name(argument)

        local found = false

        for parser_ in _iter_parsers(current_parser) do
            if parser_.name == argument_name then
                found = true
                previous_parser = current_parser
                current_parser = parser_

                break
            end
        end

        if not found then
            found = _compute_exact_flag_match(argument_name, current_parser, tabler.get_slice(arguments, index))

            if not found then
                found = _compute_exact_position_match(argument_name, current_parser)
            end

            if not found then
                return nil, previous_parser or self
            end
        end
    end

    return { current_parser }, previous_parser

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
    -- -- for _, argument_ in ipairs(current_parser:get_position_arguments()) do
    -- --     if not argument_:is_exhausted() and not vim.tbl_isempty(_get_array_startswith(_get_recommended_position_names(argument_), argument_name)) then
    -- --         -- TODO: Handle this scenario. Need to do nargs checks and stuff
    -- --         argument_:increment_used()
    -- --     end
    -- -- end
    -- --
    -- -- -- TODO: Might need to consider choices values here.
    -- -- for _, argument_ in ipairs(current_parser:get_flag_arguments()) do
    -- --     if not argument_:is_exhausted() and not vim.tbl_isempty(_get_array_startswith(argument_.names, argument_name)) then
    -- --         -- TODO: Handle this scenario. Need to do nargs checks and stuff
    -- --         argument_:increment_used()
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

--- Parse user text `data`.
---
--- @param data string | argparse.ArgparseResults
---     User text that needs to be parsed. e.g. `hello "World!"`
--- @param namespace argparse2.Namespace?
---     All pre-existing, default parsed values. If this is the first
---     argparse2.ArgumentParser then this argument will always be empty but a nested
---     parser will usually have the parsed arguments of the parent subparsers
---     that were before it.
--- @return argparse2.Namespace
---     All of the parsed data as one group.
---
function M.ArgumentParser:_parse_arguments(data, namespace)
    if type(data) == "string" then
        data = argparse.parse_arguments(data)
    end

    -- TODO: Merge namespaces more cleanly
    namespace = namespace or {}
    _merge_namespaces(namespace, self._defaults, self:_get_default_namespace())

    local position_arguments = vim.deepcopy(self:get_position_arguments())
    local flag_arguments = vim.deepcopy(self:get_flag_arguments())
    local found = false

    -- TODO: Need to handle nargs-related code here
    for index, argument in ipairs(data.arguments) do
        if argument.argument_type == argparse.ArgumentType.position then
            --- @cast argument argparse.PositionArgument
            local argument_name = _get_argument_name(argument)

            found, _ =
                self:_handle_subparsers(argparse_helper.lstrip_arguments(data, index + 1), argument_name, namespace)

            if found then
                -- NOTE: We can only do this because `self:_handle_subparsers`
                -- calls `_parse_arguments` which creates a recursive loop.
                -- Once we finally terminate the loop and return here the
                -- `found` is the final status of all of those recursions.
                --
                return namespace
            end

            found = self:_handle_exact_position_arguments(position_arguments, argument, namespace)

            if not found then
                -- TODO: Do something about this one
            end
        elseif
            argument.argument_type == argparse.ArgumentType.named
            or argument.argument_type == argparse.ArgumentType.flag
        then
            --- @cast argument argparse.FlagArgument | argparse.NamedArgument
            found = self:_handle_exact_flag_arguments(flag_arguments, argument, namespace)

            if not found then
                -- TODO: Do something about this one
            end
        end

        if not found then
            -- TODO: Add a unittest
            -- NOTE: We lost our place in the parse so we can't continue.
            return {}
        end
    end

    return namespace
end

--- (Assuming argument counts were modified by any function) Reset counts back to zero.
function M.ArgumentParser:_reset_used()
    for argument in tabler.chain(self:get_position_arguments(), self:get_flag_arguments()) do
        argument._used = 0
    end
end

--- Get auto-complete options based on this instance + the user's `data` input.
---
--- @param data argparse.ArgparseResults | string The user input.
--- @param column number? A 1-or-more value that represents the user's cursor.
--- @return string[] # All found auto-complete options, if any.
---
function M.ArgumentParser:get_errors(data, column)
    if type(data) == "string" then
        data = argparse.parse_arguments(data)
    end

    column = column or #data.text
    local stripped = _rstrip_input(data, column)

    local parsers = self:_compute_matching_parsers(stripped.arguments)

    if not parsers then
        -- TODO: Need to handle this case (when there's bad user input)
        return { "TODO: Need to write for this case" }
    end

    local unused_parsers = _get_unused_required_subparsers(parsers)

    if not vim.tbl_isempty(unused_parsers) then
        local names = _get_parsers_names(unused_parsers)

        return {
            string.format(
                'Your command is incomplete. Please choose one of these sub-commands "%s" to continue.',
                vim.fn.join(vim.fn.sort(names))
            ),
        }
    end

    local arguments = _get_incomplete_arguments(parsers)

    if not vim.tbl_isempty(arguments) then
        local names = _get_arguments_names(arguments)
        return { string.format('Required arguments "%s" were not given.', vim.fn.sort(names)) }
    end

    return {}
end

--- Get auto-complete options based on this instance + the user's `data` input.
---
--- @param data argparse.ArgparseResults | string The user input.
--- @param column number? A 1-or-more value that represents the user's cursor.
--- @return string[] # All found auto-complete options, if any.
---
function M.ArgumentParser:get_completion(data, column)
    local result = self:_get_completion(data, column)

    self:_reset_used()

    return result
end

-- TODO: Fix docstring
--- @return string # A one/two liner explanation of this instance's expected arguments.
function M.ArgumentParser:get_concise_help(data)
    if type(data) == "string" then
        data = argparse.parse_arguments(data)
    end

    local parser = self:_get_leaf_parser(data)
    local result = M.ArgumentParser._get_usage_summary(parser)

    return result .. "\n"
end

-- TODO: Fix docstring
--- @return string # A multi-liner explanation of this instance's expected arguments.
function M.ArgumentParser:get_full_help(data)
    if type(data) == "string" then
        data = argparse.parse_arguments(data)
    end

    local parser = self:_get_leaf_parser(data)
    local summary = M.ArgumentParser._get_usage_summary(parser)

    local position_text = _get_parser_position_help_text(parser)
    local flag_text = _get_parser_flag_help_text(parser)

    local output = summary

    if not vim.tbl_isempty(position_text) then
        output = output .. "\n\n" .. vim.fn.join(position_text, "\n")
    end

    if not vim.tbl_isempty(flag_text) then
        output = output .. "\n\n" .. vim.fn.join(flag_text, "\n")
    end

    output = output .. "\n"

    return output
end

--- @return argparse2.Argument[] # Get all arguments that can be placed in any order.
function M.ArgumentParser:get_flag_arguments()
    return self._flag_arguments
end

--- @return string[] # Get all of auto-complete options for this instance.
function M.ArgumentParser:get_names()
    if self.choices then
        return self.choices()
    end

    return { self.name }
end

function M.ArgumentParser:get_parent_parser()
    if not self._parent then
        return nil
    end

    -- TODO: Maybe use a stack here. But probably fine without
    return self._parent._parent
end

--- @return argparse2.Argument[] # Get all arguments that must be put in a specific order.
function M.ArgumentParser:get_position_arguments()
    return self._position_arguments
end

--- Create a child argument so we can use it to parse text later.
---
--- @param options argparse2.ArgumentOptions All of the settings to include in the new argument.
--- @return argparse2.Argument # The created `argparse2.Argument` instance.
---
function M.ArgumentParser:add_argument(options)
    _validate_argument_names(options)
    _expand_argument_options(options)

    local new_options = vim.tbl_deep_extend("force", options, { parent = self })

    local argument = M.Argument.new(new_options)

    if _is_position_name(options.names[1]) then
        table.insert(self._position_arguments, argument)
    else
        table.insert(self._flag_arguments, argument)
    end

    return argument
end

--- Create a group so we can add nested parsers underneath it later.
---
--- @param options argparse2.SubparsersOptions Customization options for the new argparse2.Subparsers.
--- @return argparse2.Subparsers # A new group of parsers.
---
function M.ArgumentParser:add_subparsers(options)
    local new_options = vim.tbl_deep_extend("force", options, { parent = self })
    local subparsers = M.Subparsers.new(new_options)

    table.insert(self._subparsers, subparsers)

    return subparsers
end

function M.ArgumentParser:parse_arguments(data)
    local results = self:_parse_arguments(data, {})

    self:_reset_used()

    return results
end

-- function M.ArgumentParser:_get_matches(argument)
--     if argument.argument_type == argparse.ArgumentType.position then
--         local output = {}
--         local name = _get_argument_name(argument)
--
--         for _, subparser in ipairs(self._subparsers) do
--             for _, parser in ipairs(subparser:get_parsers()) do
--                 if parser.name == name then
--                     -- TODO: Finish
--                     print("ASDASD")
--                 end
--             end
--         end
--
--         local positions = self:_get_position_arguments()
--
--         for _, position in ipairs(positions) do
--         end
--
--         return output
--     end
--
--     return {}
-- end

-- function M.ArgumentParser:_get_position_arguments()
--     local output = {}
--
--     for _, argument in ipairs(self._position_arguments) do
--         if argument.argument_type == argparse.ArgumentType.position then
--             table.insert(output, argument)
--         end
--     end
--
--     return output
-- end

--- Whenever this parser is visited add all of these values to the resulting namespace.
---
--- @param data table<string, any>
---     All of the data to set onto the namespace when it's found.
---
function M.ArgumentParser:set_defaults(data)
    self._defaults = data
end

--- Whenever this parser is visited, return `{execute=caller}` so people can use it.
---
--- @param caller fun(any): any
---     A function that runs a specific parser command. e.g. a "Hello, World!" program.
---
function M.ArgumentParser:set_execute(caller)
    self._defaults.execute = caller
end

return M
