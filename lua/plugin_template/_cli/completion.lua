--- Run auto-completion results for a Vim command CLI.
---
--- @module 'plugin_template._cli.completion'
---

local argparse = require("plugin_template._cli.argparse")
local argparse_helper = require("plugin_template._cli.argparse_helper")
local texter = require("plugin_template._core.texter")
local vlog = require("plugin_template._vendors.vlog")

--- @class CompletionContext
---     When an option defines `choices` as a function, this data is the given argument.
--- @field current_options CompletionOption[]
---     The auto-completion values that are currently being considered, in total.
--- @field text string
---     If the user has already written some value. e.g. `--foo=bar` will be
---     passed as `"bar"`.

--- @class BaseOption
---     A base class to inherit all Options from.
--- @field count OptionCount
---     The number of times that this option can be used.
--- @field required boolean
---     If `true`, this option must be exhausted before more arguments can be parsed.
--- @field used number
---     The number of times that this option has been used already (0-or-greater value).

--- @class DynamicOption : BaseOption
---     An argument that has a name but no value. It starts with either - or --
---     Examples: `-f` or `--foo` or `--foo-bar`
--- @field choices fun(data: CompletionContext?): string[]
---     Since `NamedOption` requires a name + value, `choices` is used to
---     auto-complete its values, starting at `--foo=`.
--- @field option_type "__dynamic"
---     This class's type.

--- @class FlagOption : BaseOption
---     An argument that has a name but no value. It starts with either - or --
---     Examples: `-f` or `--foo` or `--foo-bar`
--- @field name string
---     The text of the flag. e.g. The `"foo"` part of `"--foo"`.
--- @field option_type "__flag"
---     This class's type.

--- @class NamedOption : BaseOption
---     A --key=value pair. Basically it's a FlagArgument that has an extra value.
--- @field choices (string[] | fun(data: CompletionContext?): string[])?
---     Since `NamedOption` requires a name + value, `choices` is used to
---     auto-complete its values, starting at `--foo=`.
--- @field name string
---     The text of the argument. e.g. The `"foo"` part of `"--foo=bar"`.
--- @field option_type "__named"
---     This class's type.

--- @class PositionOption: BaseOption
---     An argument that is just text. e.g. `"foo bar"` is two positions, foo and bar.
--- @field value string
---     The position's label.
--- @field option_type "__position"
---     This class's type.

--- @alias OptionCount OptionCountNumber | OptionCountSpecialStar
---     A description of how many times a specific completion option can be used.

--- @alias OptionCountNumber number
---     The option can be used exactly N number of times. (1-or-more).

--- @alias OptionCountSpecialStar `"*"`
---     The option can be used 0-or-more times.

--- @alias CompletionOption FlagOption | NamedOption | PositionOption

--- @alias IncompleteOptionTree (string | string[] | CompletionOption | CompletionOption[])[]
---     A basic CLI description that answers. 1. What arguments are next 2.
---     What should we return for auto-complete, if anything.

--- @alias OptionTree CompletionOption[] | table<CompletionOption[], OptionTree | CompletionOption[]>
---     A basic CLI description that answers. 1. What arguments are next 2.
---     What should we return for auto-complete, if anything.

--- @alias ArgumentTree table<...>
---     A (incomplete) tree of arguments. This typically includes "What
---     aruments are next" but cannot answer questions like "What should we
---     return for auto-complete".

--- @class OptionValidationResult
---     All of the validation details. Did validation succeed? Fail? If failed, why?
--- @field success boolean
---     If validation failed, `success` is `false`.
--- @field messages string[]
---     If validation failed, this shows all of the error messages. Otherwise
---     `messages` is empty.

local M = {}

local _ANY_COUNT = "*"

--- @enum OptionType
M.OptionType = {
    dynamic = "__dynamic",
    flag = argparse.ArgumentType.flag,
    named = argparse.ArgumentType.named,
    position = argparse.ArgumentType.position,
}

--- @param option CompletionOption
--- @return boolean
local function _has_fixed_count(option)
    return type(option.count) == "number"
end

--- @param option CompletionOption
--- @return boolean
local function _has_uses_left(option)
    return option.used < option.count
end

--- Check if `options` needs to be included in the user's arguments.
---
--- @param options CompletionOption[] All auto-complete options.
--- @return boolean # If any `options` is required, return `true`.
---
local function _has_required_option(options)
    for _, option in ipairs(options) do
        if option.required then
            return true
        end
    end

    return false
end

--- Check if `options` has any count-enabled arguments that still have usages left.
---
--- @param options CompletionOption[] A complete list of `options` to consider.
--- @return boolean # If all of `options` don't have any counts left, return `true`.
---
local function _is_exhausted(options)
    for _, option in ipairs(options) do
        if _has_fixed_count(option) and not _has_uses_left(option) then
            return true
        end
    end

    return false
end

--- Check if `data` is a fully-filled-out `option`.
---
--- @param data ArgparseArgument
---     An argument that may be fully-filled-out or might be partially written
---     by a user. If it is partially written, it is not included in the return.
--- @param option CompletionOption
---     All possible auto-complete tree options (fully-filled-out).
--- @param require_value boolean?
---     If `true`, then `data` cannot be a partially-written argument. This is
---     usually for "unfinished named arguments" and not something that you'd
---     usually need.
--- @return boolean
---     If `option` matches `data`.
---
local function _is_exact_match(data, option, require_value)
    if
        data.argument_type == argparse.ArgumentType.position
        and data.argument_type == option.option_type
        and not _is_exhausted({ option })
    then
        return option.value == data.value
    end

    if
        data.argument_type == argparse.ArgumentType.named
        and data.argument_type == option.option_type
        and not _is_exhausted({ option })
        and (not require_value or (require_value and data.value))
    then
        return option.name == data.name
    end

    return false
end

--- Check if `data` is actually an unfinished / partial named argument.
---
--- @param data ArgparseArgument A (maybe) partially written user argument.
--- @param option CompletionOption The option to check for a match.
--- @return boolean # If there's a match, return `true`.
---
local function _is_partial_match_named_argument(data, option)
    if
        data.argument_type == argparse.ArgumentType.named
        and data.argument_type == option.option_type
        and not _is_exhausted({ option })
        and option.name ~= data.name
        and vim.startswith(option.name, data.name)
    then
        return true
    end

    if
        data.argument_type == argparse.ArgumentType.flag
        and option.option_type == M.OptionType.named
        and not _is_exhausted({ option })
        and option.name ~= data.name
        and vim.startswith(option.name, data.name)
    then
        -- NOTE: When we're in the middle of typing `--foo`, we don't know if
        -- it will end as just `--foo` or if it will become `--foo=bar` so we
        -- have to assume that it could.
        --
        return true
    end

    return false
end

--- Find the label name of `option`.
---
--- - --foo = foo
--- - --foo=bar = foo
--- - -f = f
--- - foo = foo
---
--- @param argument ArgparseArgument Some argument / option to query.
--- @return string # The found name.
---
local function _get_argument_name(argument)
    if argument.argument_type == M.OptionType.position then
        --- @cast argument PositionArgument
        return argument.value
    end

    if
        argument.argument_type == argparse.ArgumentType.flag
        or argument.argument_type == argparse.ArgumentType.named
    then
        return argument.name
    end

    vlog.fmt_error('Unabled to find a label for "%s" argument.', argument)

    return ""
end

--- Find all `options` that match `argument`.
---
--- @param data ArgparseArgument A partially written user argument.
--- @param option CompletionOption The option to check for a match.
--- @return boolean # If there's a match, return `true`.
---
local function _is_partial_match(data, option)
    if
        data.argument_type == argparse.ArgumentType.position
        and data.argument_type == option.option_type
        and not _is_exhausted({ option })
    then
        return option.value ~= data.value and vim.startswith(option.value, data.value)
    end

    if _is_partial_match_named_argument(data, option) then
        return true
    end

    return false
end

--- Check if `left` roughly matches `right`.
---
--- Different options could have different values but as long as the option's
--- names both match, this function returns `true`.
---
--- @param left CompletionOption The first option to check for.
--- @param right CompletionOption Another option to check against.
--- @return boolean # If there is a match, return `true`.
---
local function _is_similar_option(left, right)
    if left.option_type ~= right.option_type then
        return false
    end

    if left.option_type == M.OptionType.named or left.option_type == M.OptionType.flag then
        return left.name == right.name
    end

    if left.option_type == M.OptionType.position then
        return left.value == right.value
    end

    if left.option_type == M.OptionType.dynamic then
        return left.choices == right.choices
    end

    vlog.warn(
        'Got "%s / %s" left / right values. We are not sure how to parse them.',
        vim.inspect(left),
        vim.inspect(right)
    )

    return false
end

--- Convert options class instances into raw auto-completion text.
---
--- @param options CompletionOption[]
---     All auto-completion data to extract for text.
--- @return string[]
---     The found auto-completion text.
---
local function _get_auto_complete_values(options, text)
    local output = {}

    for _, option in ipairs(options) do
        if option.option_type == M.OptionType.position then
            table.insert(output, option.value)
        elseif option.option_type == M.OptionType.flag then
            table.insert(output, "-" .. option.name)
        elseif option.option_type == M.OptionType.named then
            table.insert(output, "--" .. option.name .. "=")
        elseif option.option_type == M.OptionType.dynamic then
            vim.list_extend(
                output,
                option.choices(
                    { current_options = options, text = text }
                )
            )
        end
    end

    table.sort(output, function(left, right)
        return left < right
    end)

    return output
end

--- Scan `input` and stop processing arguments after `column`.
---
--- @param input ArgparseResults
---     The user's parsed text.
--- @param column number
---     The point to stop checking for arguments. Must be a 1-or-greater value.
--- @return number
---     The found index. If all arguments are < `column` then the returning
---     index will cover all of `input.arguments`.
---
local function _get_cursor_offset(input, column)
    for index, argument in ipairs(input.arguments) do
        if argument.range.end_column > column then
            return index
        end
    end

    return #input.arguments
end

--- Check if `data` is a fully-filled-out argument and also found in `options`.
---
--- @param data ArgparseArgument
---     An argument that may be fully-filled-out or might be partially written
---     by a user. If it is partially written, it is not included in the return.
--- @param options CompletionOption[]
---     All possible auto-complete tree options (fully-filled-out).
--- @param require_value boolean?
---     If `true`, then `data` cannot be a partially-written argument. This is
---     usually for "unfinished named arguments" and not something that you'd
---     usually need.
--- @return CompletionOption[]
---     All `options` that match `data`.
---
local function _get_exact_matches(data, options, require_value)
    if require_value == nil then
        require_value = true
    end

    local output = {}

    for _, option in ipairs(options) do
        if _is_exact_match(data, option, require_value) then
            table.insert(output, option)
        end
    end

    return output
end

--- Get the readable label of `option`, if it has one.
---
--- @param option CompletionOption Any option that has a "query-able" name.
--- @return string # The found name, if any.
---
local function _get_option_name(option)
    if option.option_type == M.OptionType.position then
        --- @cast option PositionOption
        return option.value
    end

    if option.option_type == M.OptionType.flag or option.option_type == M.OptionType.named then
        return option.name
    end

    if option.option_type == M.OptionType.dynamic then
        return ""
    end

    vlog.fmt_error('Unabled to find a label for "%s" option.', option)

    return ""
end

--- Find every option that exact-matches `name`.
---
--- If any group of options matches `text`, all options in that group are returned.
---
--- @param text string
---     Some label that is either part of an argument like `"foo"` from
---     `"--foo"`, `"--foo=bar"`, or `"foo"`.
--- @param all_options CompletionOption[][]
---     Each group of options to consider for matching.
--- @return CompletionOption[]?
---     All found matches, if any.
---
local function _get_option_matches(text, all_options)
    for _, options in ipairs(all_options) do
        for _, option in ipairs(options) do
            if text == _get_option_name(option) then
                return options
            elseif option.option_type == M.OptionType.dynamic then
                local choices = option.choices({ current_options = options, text = text })

                if vim.tbl_contains(choices, text) then
                    return options
                end
            end
        end
    end

    return nil
end

--- Increase the "used" counter of the options.
---
--- @param all_options CompletionOption[]
---     All options that were auto-completion candidates but did not match.
--- @param matching_options CompletionOption[]
---     All options that matched as auto-completion candidates.
---
local function _increment_used(all_options, matching_options)
    for _, option in ipairs(all_options) do
        for _, matching_option in ipairs(matching_options) do
            if _is_similar_option(option, matching_option) then
                if _get_option_name(option) == _get_option_name(matching_option) then
                    if type(option.count) == "number" then
                        option.used = option.used + 1
                    end
                end
            end
        end
    end
end

--- Find all `options` that match `argument`.
---
--- @param argument ArgparseArgument A partially written user argument.
--- @param options CompletionOption[] The options to consider for auto-completion.
--- @return CompletionOption[] # All options that match part of `argument`.
---
local function _get_partial_matches(argument, options)
    local output = {}

    for _, option in ipairs(options) do
        if _is_partial_match(argument, option) then
            table.insert(output, option)
        end
    end

    return output
end

--- Check if `options` have been used up (and we are ready to get more options).
---
--- @param options CompletionOption[] All options used in current / previous runs.
--- @return boolean # If `options` still has required uses, return `false`.
---
local function _needs_next_options(options)
    for _, option in ipairs(options) do
        if option.required and _has_fixed_count(option) and _has_uses_left(option) then
            return false
        end
    end

    return true
end

--- Get all auto-complete option from `options` that still has uses left.
---
--- @param options CompletionOption[]
---     All options which may or may not have been already used.
--- @return CompletionOption[]
---     Any `options` that still need / want to be used.
---
local function _trim_exhausted_options(options)
    local output = {}

    for _, option in ipairs(options) do
        if not _is_exhausted({ option }) then
            table.insert(output, option)
        end
    end

    return output
end

--- Remove the ending `index` options from `input`.
---
--- @param input ArgparseResults
---     The parsed arguments + any remainder text.
--- @param column number
---     The found index. If all arguments are < `column` then the returning
---     index will cover all of `input.arguments`.
--- @return ArgparseResults
---     The stripped copy from `input`.
---
local function _rstrip_input(input, column)
    local stripped = argparse_helper.rstrip_arguments(input, _get_cursor_offset(input, column))

    local last = stripped.arguments[#stripped.arguments]

    if last then
        stripped.remainder.value = input.text:sub(last.range.end_column + 1, #input.text)
    end

    stripped.text = input.text:sub(1, column)

    return stripped
end

--- Look within `options` for a flag like `-f` by name.
---
--- @param options CompletionOption[]
---     Some auto-completion options to consider. It might contain flag
---     / position / named arguments.
--- @param name string
---     The argument to search for. e.g. `"f"`.
--- @return FlagOption[]
---     All found flags, if any.
---
local function _get_flag_arguments(options, name)
    local output = {}

    for _, option in ipairs(options) do
        if option.option_type == M.OptionType.flag and option.name == name then
            table.insert(output, name)
        end
    end

    return output
end

--- Change `argument` flag to a named argument.
---
--- @param argument FlagArgument An `"--foo"` argument that doesn't expect a value.
--- @return NamedArgument # An `"--foo=..."` argument that expects a value.
---
local function _convert_flag_to_named_argument(argument)
    local copy = vim.deepcopy(argument)
    copy.argument_type = argparse.ArgumentType.named
    copy.needs_choice_completion = false

    return copy
end

--- If there is one, grab the final argument `--foo=` argument.
---
--- The `--foo=` is "unfinished" because it's missing a value.
---
--- @param argument ArgparseArgument
---     The argument to check for a match.
--- @param options CompletionOption[]
---     Some auto-completion options to consider. It might contain flag
---     / position / named arguments.
--- @return NamedArgument?
---     The found named argument, if any.
---
local function _get_remainder_named_argument(argument, options)
    if argument.argument_type == argparse.ArgumentType.named then
        --- @cast argument NamedArgument

        return argument
    end

    if
        argument.argument_type == argparse.ArgumentType.flag
        and not vim.tbl_contains(_get_flag_arguments(options, argument.name))
    then
        --- @cast argument FlagArgument

        -- NOTE: This happens when the user has written `--foo`. We know from
        -- the `options` that this needs to be `--foo={bar, fizz, buzz}` but
        -- they haven't written the full argument name yet.
        --
        -- Instead of assuming that they want to complete the argument choies
        -- of `foo`, we just auto-complete for `foo`.
        --
        local named_last = _convert_flag_to_named_argument(argument)
        local matches = _get_exact_matches(named_last, options, false)

        if vim.tbl_isempty(matches) then
            return nil
        end

        named_last.needs_choice_completion = false

        return named_last
    end

    return nil
end

--- Find all `options` that matches the name/label of `argument`.
---
--- @param argument ArgparseArgument A user CLI setting to search for.
--- @param options CompletionOption[] All possible completion options.
--- @return CompletionOption[] # The found matches.
---
local function _get_name_matches(argument, options)
    local name = _get_argument_name(argument)
    local output = {}

    for _, option in ipairs(options) do
        if name == _get_option_name(option) and argument.argument_type == option.option_type then
            table.insert(output, option)
        end
    end

    return output
end

--- Get the named auto-complete options, if any.
---
--- @param option NamedOption The named option to grab from.
--- @param current_value string An existing value for the argument, if any.
--- @param options CompletionOption[] All options that are currently being considered.
--- @return string[] # The found auto-complete options, if any.
---
local function _get_named_option_choices(option, current_value, options)
    if not option.choices then
        return {}
    end

    if type(option.choices) == "function" then
        return option.choices({ current_options = options, text = current_value })
    end

    local choices = option.choices
    --- @cast choices string[]

    return choices
end

--- Find all named arguments, e.g. `--foo=bar` style arguments.
---
--- @param options CompletionOption[]
---     Some auto-completion options to consider. It might contain flag
---     / position / named arguments.
--- @return NamedOption[]
---     All found arguments, if any.
---
local function _get_named_arguments(options)
    local output = {}

    for _, option in ipairs(options) do
        if option.option_type == M.OptionType.named then
            table.insert(output, option)
        end
    end

    return output
end

--- Search `options` for a named argument that matches `data`.
---
--- @param data NamedArgument | FlagArgument
---     The unfinished named argument.
--- @return NamedOption[]
---     All named argument (e.g. `--foo=bar`) arguments.
---
local function _get_matching_unfinished_named_arguments(data, options)
    local output = {}

    for _, option in ipairs(options) do
        if
            data.argument_type == argparse.ArgumentType.named
            and data.argument_type == option.option_type
            and data.name == option.name
        then
            table.insert(output, option)
        end
    end

    return output
end

--- Get the auto-completion options for some named argument.
---
--- Important: It's assumed that this named argument doesn't already have
--- a value or the value is incomplete.
---
--- @param options CompletionOption[]
---     Some auto-completion options to consider. It might contain flag
---     / position / named arguments.
--- @param argument NamedArgument
---     The unfinished named argument.
--- @return string[]
---     The found auto-complete options.
---
local function _get_unfinished_named_argument_auto_complete_options(options, argument)
    if not argument.needs_choice_completion then
        return { string.format("--%s=", argument.name) }
    end

    options = _get_named_arguments(options)
    local matches = _get_matching_unfinished_named_arguments(argument, options)
    --- @cast matches NamedOption[]

    local output = {}
    local current_value = argument.value

    if type(current_value) == "boolean" then
        current_value = ""
    end

    for _, match in ipairs(matches) do
        for _, value in ipairs(_get_named_option_choices(match, current_value, options)) do
            if not vim.tbl_contains(output, value) then
                table.insert(output, string.format("--%s=%s", argument.name, value))
            end
        end
    end

    return output
end

--- Suggest an auto-completion function for a named argument's choices.
---
--- If a names argument is defined with choices `{"foo", "bar" "fizz"}`, the
--- returned function will match when a user types `"f"` and suggest `{"foo",
--- "fizz"}` as auto-completion options.
---
--- @param items string[]
---     All completion options to consider for the function.
--- @return fun(value: string): string[]
---     A function that takes the user's current input and auto-completes
---     remaining values.
---
local function _get_startswith_auto_complete_function(items)
    local function _get_choices(data)
        local current_value = data.text
        local output = {}

        for _, item in ipairs(items) do
            if item ~= current_value and vim.startswith(item, current_value) then
                table.insert(output, item)
            end
        end

        return output
    end

    return _get_choices
end

--- Check if `option` has only runtime behavior (unknown label(s) / choices).
---
--- @param option ... An argument that might be a `DynamicOption`.
--- @return boolean # If `DynamicOption`, return `true`.
---
local function _is_dynamic_option(option)
    return option.option_type == M.OptionType.dynamic
end

--- Check if `option` is a `--foo` flag.
---
--- @param option ... An argument that might be a `FlagOption`.
--- @return boolean # If `FlagOption`, return `true`.
---
local function _is_flag_option(option)
    return option.option_type == M.OptionType.flag
end

--- Check if `option` is a `--foo=bar` argument.
---
--- @param option ... An argument that might be a `NamedOption`.
--- @return boolean # If `NamedOption`, return `true`.
---
local function _is_named_option(option)
    return option.option_type == M.OptionType.named
end

--- Check if `option` is a `foo` argument.
---
--- @param option ... An argument that might be a `PositionOption`.
--- @return boolean # If `PositionOption`, return `true`.
---
local function _is_position_option(option)
    return option.option_type == M.OptionType.position
end

--- Check if `option` is a known completion option.
---
--- @param option CompletionOption The object to check.
--- @return boolean # If `option` is an option, return `true`.
---
local function _is_option(option)
    if not option then
        return false
    end

    if type(option) ~= "table" then
        return false
    end

    return _is_position_option(option)
        or _is_named_option(option)
        or _is_flag_option(option)
        or _is_dynamic_option(option)
end

--- Check if `options` is a list/array of options.
---
--- @param options CompletionOption[]
---     Some auto-completion options to consider.
--- @return boolean
---     If `options` is not a list of options (e.g. a dictionary) return `false`.
---
local function _is_option_array(options)
    for _, option in ipairs(options) do
        if not _is_option(option) then
            return false
        end
    end

    return true
end

--- Create a pseudo option based on `name`.
---
--- @param name string Some value to use for the new option.
--- @return PositionOption # The generated option.
---
local function _make_position_option(name)
    return { count = 1, used = 0, value = name, option_type = M.OptionType.position }
end

--- Convert `tree` into a completion tree (if it isn't already).
---
--- @param tree IncompleteOptionTree | ArgumentTree
---     The object to fill out into completion options.
--- @return OptionTree
---     The fully-parsed completion information.
---
local function _fill_missing_data(tree)
    local function _expand_option(option)
        option = vim.deepcopy(option)

        if option.count == nil then
            option.count = 1
        end

        if option.count == _ANY_COUNT then
            -- NOTE: This is a bit of a hack. Instead of adding checks for
            -- `_ANY_COUNT` everywhere, we just set the count very high so that
            -- the option is unlikely to ever expire. We'll keep this hack as
            -- long as unittests say the feature works.
            --
            option.count = 1000000000
        end

        if option.used == nil then
            option.used = 0
        end

        if option.option_type == M.OptionType.position then
            if option.required == nil then
                option.required = true
            end
        elseif option.option_type == M.OptionType.named then
            if option.required == nil then
                option.required = false
            end

            if option.choices and texter.is_string_list(option.choices) then
                --- @diagnostic disable-next-line param-type-mismatch
                option.choices = _get_startswith_auto_complete_function(option.choices)
            end
        elseif option.option_type == M.OptionType.flag then
            if option.required == nil then
                option.required = false
            end
        elseif option.option_type == M.OptionType.dynamic then
            if option.required == nil then
                option.required = false
            end
        end

        return option
    end

    local function _make_key(key)
        if type(key) == "string" then
            -- NOTE: `key` usually is a string.
            return { _make_position_option(key) }
        end

        if vim.islist(key) then
            local output = {}

            for _, key_ in ipairs(key) do
                vim.list_extend(output, _make_key(key_))
            end

            return output
        end

        if _is_option(key) then
            return { _expand_option(key) }
        end

        return key
    end

    local output = {}
    local stack = {}

    table.insert(stack, { old = tree, new = output })

    while #stack > 0 do
        local current = table.remove(stack)
        local old = current.old
        local new = current.new

        for key, value in pairs(old) do
            local new_key = _make_key(key)
            new[new_key] = {}

            if vim.islist(value) then
                for _, subvalue in ipairs(_make_key(value)) do
                    table.insert(new[new_key], subvalue)
                end
            elseif type(value) == "table" then
                if _is_option(value) then
                    new[key] = _expand_option(value)
                else
                    table.insert(stack, { old = value, new = new[new_key] })
                end
            else
                new[new_key] = value
            end
        end
    end

    return output
end

--- Recursively flatten `data` until it is just a list of `CompletionOption[]`.
---
--- @param data ... A nested list-of-lists-of-`CompletionOption[]`.
--- @return CompletionOption[] # The flattened arguments.
---
local function _flatten_to_arguments(data)
    local current = data

    while not _is_option_array(current) do
        current = vim.iter(current):flatten():totable()
    end

    return current
end

--- Either keep `tree` unmodified or flatten it into a single list of options.
---
--- @param tree OptionTree The fully-parsed completion information.
--- @return CompletionOption[] # The options to use in other functions.
---
local function _conform_current_options(tree)
    local keys

    if not vim.islist(tree) then
        keys = vim.tbl_keys(tree)
    else
        keys = tree
    end

    keys = _flatten_to_arguments(keys)
    table.sort(keys, function(left, right)
        return _get_option_name(left) < _get_option_name(right)
    end)

    return keys
end

--- Get the completion of options for `input` by traversing `tree`.
---
--- @param input ArgparseResults
---     The user's input text to parse.
--- @param tree OptionTree
---     A basic CLI description that answers. 1. What arguments are next 2.
---     What should we return for auto-complete, if anything.
--- @return OptionTree
---     The options to use in other functions.
--- @return boolean
---     If we stopped the traversal early, return `false`. Otherwise return `true`.
--- @return ArgparseArgument
---     The last argument that was processed.
---
local function _get_options_from_tree(input, tree)
    local function _filter_named_arguments_with_missing_values(argument, options)
        if argument.value and argument.value ~= "" then
            return options
        end

        local name = _get_argument_name(argument)
        local output = {}

        for _, option in ipairs(options) do
            if option.option_type == M.OptionType.named then
                if name ~= option.name then
                    table.insert(output, option)
                end
            else
                table.insert(output, option)
            end
        end

        return output
    end

    local current_tree = tree
    local total = #input.text

    for _, argument in ipairs(input.arguments) do
        if argument.range.end_column >= total then
            -- NOTE: 1. We reached the end
            --       2. The user hasn't added another space so we should not
            --       attempt to get child options.
            --
            -- Because of #2, we need to immediately return.
            --
            return current_tree, true, argument
        end

        local keys = current_tree

        if vim.islist(keys) then
            keys = _flatten_to_arguments(keys)
            -- NOTE: We've reached the end of the tree. So we don't traverse
            -- down the tree any further and just iterate over what's left.
            --
            local matches = _get_name_matches(argument, keys)

            if vim.tbl_isempty(matches) then
                return keys, false, argument
            end

            _increment_used(keys, matches)
        else
            local name = _get_argument_name(argument)
            keys = vim.tbl_keys(current_tree)
            local matches = _get_option_matches(name, keys)
            local valid_matches = _filter_named_arguments_with_missing_values(argument, matches or {})

            if vim.tbl_isempty(valid_matches) then
                return current_tree, false, argument
            end

            for _, key in ipairs(keys) do
                _increment_used(key, matches or {})
            end

            if _needs_next_options(keys) then
                current_tree = current_tree[matches]
            end
        end
    end

    return current_tree, true, input.arguments[#input.arguments]
end

--- Find all `options` that either exactly  or partially match `data`.
---
--- @param data ArgparseArgument A user CLI setting to search from.
--- @param options CompletionOption[] All possible auto-complete values to return.
--- @return CompletionOption[] # The found matches, if any.
---
local function _get_exact_or_partial_matches(data, options)
    local output = {}

    local name = _get_argument_name(data)

    for _, option in ipairs(options) do
        if _is_exact_match(data, option) then
            vim.list_extend(output, _get_auto_complete_values({ option }, name))
        elseif _is_partial_match(data, option) then
            vim.list_extend(output, _get_auto_complete_values({ option }, name))
        elseif option.option_type == M.OptionType.dynamic then
            for _, choice in ipairs(option.choices({ current_options = options, text = name })) do
                if vim.startswith(choice, name) then
                    table.insert(output, choice)
                end
            end
        end
    end

    return output
end

--- Find all of the next completion options to suggest.
---
--- @param tree OptionTree All or part of the series of auto-complete options.
--- @return CompletionOption[] # The next auto-complete candidates to consider.
---
local function _get_next_subtree_if_needed(tree)
    if vim.islist(tree) then
        return _flatten_to_arguments(tree)
    end

    return vim.tbl_keys(tree)
end

--- Find the auto-completion results for `input` and `column`, using `tree`.
---
--- The basic process goes like this:
---
--- - Find all of the arguments in `input` that are fully described (using `column`)
---     - For all found arguments, disable any that are "exhausted"
--- - If the cursor is located on an argument that is partially written...
---     - (Only consider arguments that are not "exhausted")
---     - If the argument matches by-name, add it to the auto-complete choices
---     - If the argument has choices, add those to the auto-complete choices
---         - Example: - An argument like "--foo=" may have choice
---
--- The important part is "that is partially written...". The logic for that is:
--- 1. If the argument is "foo" and there's no positional argument with that
--- name, then it must be a partial argument.
--- 2. If the argument is "-", it could be a single dash argument (flag, e.g.
--- -f) or double dash argument (named --foo=bar)
--- 3. If the argument is "--", it is probably a double dash argument
--- 4. If the argument is "--[a-z]", it is definition a double dash argument
---
--- And if all else fails, if the user's `column` is that the end of `input`
--- and the last character is " ", they are trying to auto-complete
--- for the next argument.
---
--- There's some exceptions too (e.g. if the `column` is within an argument, don't
--- auto-complete) but that's the jist.
---
--- @param tree IncompleteOptionTree | ArgumentTree
---     A basic CLI description that answers. 1. What arguments are next 2.
---     What should we return for auto-complete, if anything.
--- @param input ArgparseResults
---     The user's parsed text.
--- @param column number
---     The starting point for the argument. Must be a 1-or-greater value.
--- @return string[]
---     All of the auto-completion options that were found, if any.
---
local function _get_options(tree, input, column)
    tree = _fill_missing_data(tree)

    if vim.tbl_isempty(input.arguments) then
        if input.remainder.value == "" then
            local options = _conform_current_options(tree)

            return _get_auto_complete_values(options or {})
        end

        return {}
    end

    local stripped = _rstrip_input(input, column)

    local last = stripped.arguments[#stripped.arguments]
    local subtree, completed, _ = _get_options_from_tree(stripped, tree)
    local options = _conform_current_options(subtree)
    local argument = _get_remainder_named_argument(last, options)

    if argument and argument.argument_type == argparse.ArgumentType.named then
        if stripped.remainder.value == "" then
            -- The cursor is on the last argument
            return _get_unfinished_named_argument_auto_complete_options(options, argument)
        end
    end

    if completed then
        if stripped.remainder.value ~= "" then
            local next_subtree = _get_next_subtree_if_needed(subtree)
            options = _flatten_to_arguments(next_subtree)
            options = _trim_exhausted_options(options)

            return _get_auto_complete_values(options)
        end

        local output = _get_exact_or_partial_matches(last, options)
        table.sort(output, function(left, right)
            return left < right
        end)

        return output
    end

    local matches = _get_partial_matches(last, options)

    return _get_auto_complete_values(matches)
end

--- Find the auto-completion results for `input` and `column`, using `tree`.
---
--- @param tree IncompleteOptionTree | ArgumentTree
---     A basic CLI description that answers. 1. What arguments are next 2.
---     What should we return for auto-complete, if anything.
--- @param input ArgparseResults
---     The user's parsed text.
--- @param column number
---     The starting point for the argument. Must be a 1-or-greater value.
--- @return string[]
---     All of the auto-completion options that were found, if any.
---
function M.get_options(tree, input, column)
    local results = _get_options(tree, input, column)

    vlog.fmt_debug('Got "%s" auto-completion results.', results)

    return results
end

--- Check if `input` satisfies the expected `tree`.
---
--- @param tree IncompleteOptionTree | ArgumentTree
---     A basic CLI description that answers. 1. What arguments are next 2.
---     What should we return for auto-complete, if anything.
--- @param input ArgparseResults
---     The user's parsed text.
--- @return OptionValidationResult
---     All of the validation details. Did validation succeed? Fail? If failed, why?
---
function M.validate_options(tree, input)
    local function _get_validation_messages(argument)
        if argument and argument.argument_type == argparse.ArgumentType.named then
            --- @cast argument NamedArgument

            if not argument.value or argument.value == "" then
                return {
                    string.format('Named argument "%s" needs a value.', argument.name),
                }
            end
        end

        return {}
    end

    tree = _fill_missing_data(tree)

    if vim.tbl_isempty(input.arguments) then
        if _has_required_option(_conform_current_options(tree)) then
            return { success = false, messages = { "Arguments cannot be empty." } }
        end

        return { success = true, messages = {} }
    end

    local subtree, _, argument = _get_options_from_tree(input, tree)

    local messages = _get_validation_messages(argument)

    if not vim.tbl_isempty(messages) then
        return { success = false, messages = messages }
    end

    local options = _conform_current_options(subtree)
    options = _trim_exhausted_options(options)

    if vim.tbl_isempty(options) then
        return { success = true, messages = {} }
    end

    local labels = _get_auto_complete_values(options)

    messages = {
        string.format('Missing argument. Need one of: "%s".', vim.fn.join(labels, ", ")),
    }

    return { success = false, messages = messages }
end

return M
