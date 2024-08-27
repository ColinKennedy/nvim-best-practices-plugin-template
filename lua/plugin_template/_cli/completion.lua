--- Run auto-completion results for a Vim command CLI.
---
--- @module 'plugin_template._cli.completion'
---

local argparse = require("plugin_template._cli.argparse")
local argparse_helper = require("plugin_template._cli.argparse_helper")
local vlog = require("plugin_template._vendors.vlog")

--- @class FlagOption : FlagArgument
---     An argument that has a name but no value. It starts with either - or --
---     Examples: `-f` or `--foo` or `--foo-bar`
--- @field required boolean
---     If `true`, this option must be exhausted before more arguments can be parsed.
--- @field used number
---     The number of times that this option has been used already (0-or-greater value).
--- @field count OptionCount
---     The number of times that this option can be used.

--- @class NamedOption : NamedArgument
---     A --key=value pair. Basically it's a FlagArgument that has an extra value.
--- @field used number
---     The number of times that this option has been used already (0-or-greater value).
--- @field choices (string[] | fun(current_value: string): string[])?
---     Since `NamedOption` requires a name + value, `choices` is used to
---     auto-complete its values, starting at `--foo=`.
--- @field count OptionCount
---     The number of times that this option can be used.

--- @class PositionOption: PositionArgument
---     An argument that is just text. e.g. `"foo bar"` is two positions, foo and bar.
--- @field used number
---     The number of times that this option has been used already (0-or-greater value).
--- @field count OptionCount
---     The number of times that this option can be used.

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

--- @alias OptionTree CompletionOption[]
---     A basic CLI description that answers. 1. What arguments are next 2.
---     What should we return for auto-complete, if anything.

--- @alias ArgumentTree ArgparseArgument[]
---     A basic CLI description that answers. 1. What arguments are next 2.
---     What should we return for auto-complete, if anything.

local M = {}

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
        and data.argument_type == option.argument_type
        and not _is_exhausted({ option })
    then
        return option.value == data.value
    end

    if
        data.argument_type == argparse.ArgumentType.named
        and data.argument_type == option.argument_type
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
        and data.argument_type == option.argument_type
        and not _is_exhausted({ option })
        and option.name ~= data.name
        and vim.startswith(option.name, data.name)
    then
        return true
    end

    if
        data.argument_type == argparse.ArgumentType.flag
        and option.argument_type == argparse.ArgumentType.named
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

--- Find all `options` that match `argument`.
---
--- @param data ArgparseArgument A partially written user argument.
--- @param option CompletionOption The option to check for a match.
--- @return boolean # If there's a match, return `true`.
---
local function _is_partial_match(data, option)
    if
        data.argument_type == argparse.ArgumentType.position
        and data.argument_type == option.argument_type
        and not _is_exhausted({ option })
    then
        return option.value ~= data.value and vim.startswith(option.value, data.value)
    end

    if _is_partial_match_named_argument(data, option) then
        return true
    end

    return false
end

-- local function _is_user_getting_the_next_input_argument(input)
--     return input.remainder.value == " "
-- end

--- Convert options class instances into raw auto-completion text.
---
--- @param options CompletionOption[]
---     All auto-completion data to extract for text.
--- @return string[]
---     The found auto-completion text.
---
local function _get_auto_complete_values(options)
    local output = {}

    for _, option in ipairs(options) do
        if option.argument_type == argparse.ArgumentType.position then
            table.insert(output, option.value)
        elseif option.argument_type == argparse.ArgumentType.flag then
            table.insert(output, "-" .. option.name)
        elseif option.argument_type == argparse.ArgumentType.named then
            table.insert(output, "--" .. option.name .. "=")
        end
    end

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

-- --- Check if `options` has at least one position argument.
-- ---
-- --- @param options ArgparseArgument[]
-- --- @return boolean # Return `true` if there's at least one position argument found.
-- ---
-- local function _has_positional_argument(options)
--     for _, option in ipairs(options) do
--         if option.argument_type == argparse.ArgumentType.position then
--             return true
--         end
--     end
--
--     return false
-- end

--- Find the label name of `option`.
---
--- - --foo = foo
--- - --foo=bar = foo
--- - -f = f
--- - foo = foo
---
--- @param option ArgparseArgument Some argument / option to query.
--- @return string # The found name.
---
local function _get_argument_name(option)
    if option.argument_type == argparse.ArgumentType.position then
        --- @cast option PositionOption
        return option.value
    end

    if option.argument_type == argparse.ArgumentType.flag or option.argument_type == argparse.ArgumentType.named then
        return option.name
    end

    -- TODO: Add error
    return ""
end

--- Increase the "used" counter of the options.
---
--- @param all_options CompletionOption[]
---     All options that were auto-completion candidates but did not match.
--- @param matching_options CompletionOption[]
---     All options that matched as auto-completion candidates.
---
local function _increment_used(all_options, matching_options)
    local names = {}

    for _, option in ipairs(matching_options) do
        table.insert(names, _get_argument_name(option))
    end

    local position_found = false

    for _, option in ipairs(all_options) do
        if vim.tbl_contains(names, _get_argument_name(option)) then
            if type(option.count) == "number" then
                option.used = option.used + 1

                if option.argument_type == argparse.ArgumentType.position then
                    position_found = true
                end
            end
        end
    end

    if position_found then
        for _, option in ipairs(all_options) do
            if option.argument_type == argparse.ArgumentType.position and _has_fixed_count(option) then
                option.used = option.count
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

-- local function _get_required_options(options)
--     local output = {}
--
--     for _, option in ipairs(options) do
--         if option.required then
--             table.insert(output, option)
--         end
--     end
--
--     return output
-- end

--- Find all `options` that match `argument`.
---
--- @param argument ArgparseArgument A partially written user argument.
--- @param options CompletionOption[] The options to consider for auto-completion.
--- @return CompletionOption[] # All options that match part of `argument`.
---
local function _handle_partial_matches(argument, options)
    local matches = _get_partial_matches(argument, options)

    if vim.tbl_isempty(matches) then
        return {}
    end

    _increment_used(options, matches)

    return matches
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
        if option.argument_type ~= argparse.ArgumentType.position and not _is_exhausted({ option }) then
            table.insert(output, option)
        end
    end

    return output
end

--- @param tree OptionTree
---     A basic CLI description that answers. 1. What arguments are next 2.
---     What should we return for auto-complete, if anything.
--- @param input ArgparseResults
---     The user's parsed text.
--- @return CompletionOption[]?
---     The options to consider for auto-completion.
--- @return number
---     The starting point of the argument "tree" used to gather the options.
---
local function _compute_completion_options(tree, input)
    local tree_index = 1
    local current_options = tree[tree_index]
    local input_count = #input.arguments

    for index = 1, input_count do
        local argument = input.arguments[index]
        local matches = _get_exact_matches(argument, current_options)

        if vim.tbl_isempty(matches) then
            if index == input_count then
                return current_options, tree_index
            end

            -- NOTE: Something went wrong. The user must've mistyped something.
            --
            -- Since we no longer know where we are in the tree, it's not
            -- a great idea to show any auto-complete so instead show nothing.
            --
            return nil, tree_index
        end

        _increment_used(current_options, matches)

        if _needs_next_options(current_options) then
            current_options = _trim_exhausted_options(current_options)
            tree_index = tree_index + 1
            vim.list_extend(current_options, tree[tree_index] or {})
        end
    end

    return current_options, tree_index
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
        if option.argument_type == argparse.ArgumentType.flag and option.name == name then
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
--- @param input ArgparseResults The some argument / completion information.
--- @param tree OptionTree The fully-parsed completion information.
--- @return ArgparseArgument? # The found named argument, if any.
---
local function _get_remainder_named_argument(input, tree)
    local last = input.arguments[#input.arguments] or {}

    if last.argument_type == argparse.ArgumentType.named then
        return last
    end

    local options = tree[#tree]

    if
        last.argument_type == argparse.ArgumentType.flag
        and not vim.tbl_contains(_get_flag_arguments(options, last.name))
    then
        --- @cast last FlagOption

        -- NOTE: This happens when the user has written `--foo`. We know from
        -- the tree that this needs to be `--foo={bar, fizz, buzz}` but they
        -- haven't written the full argument name yet.
        --
        -- Instead of assuming that they want to complete the argument choies
        -- of `foo`, we just auto-complete for `foo`.
        --
        local named_last = _convert_flag_to_named_argument(last)
        local matches = _get_exact_matches(named_last, options, false)

        if vim.tbl_isempty(matches) then
            return nil
        end

        named_last.needs_choice_completion = false

        return named_last
    end

    return nil
end

--- Get the named auto-complete options, if any.
---
--- @param option NamedOption The named option to grab from.
--- @param current_value string An existing value for the argument, if any.
--- @return string[] # The found auto-complete options, if any.
---
local function _get_named_option_choices(option, current_value)
    if not option.choices then
        return {}
    end

    if type(option.choices) == "function" then
        return option.choices(current_value)
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
        if option.argument_type == argparse.ArgumentType.named then
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
--- @param tree OptionTree
---     The fully-parsed completion information.
--- @param argument ArgparseArgument
---     The unfinished named argument, if any.
--- @return string[]
---     The found auto-complete options.
---
local function _get_unfinished_named_argument_auto_complete_options(tree, argument)
    if not argument.needs_choice_completion then
        return { string.format("--%s=", argument.name) }
    end

    -- TODO: Get these options more intelligently. This section needs to consider
    -- flags that are `count="*"` because they could also be options
    --
    local options = tree[#tree]
    options = _get_named_arguments(options)
    local matches = _get_exact_matches(argument, options, false)
    --- @cast matches NamedOption[]

    local output = {}
    local current_value = argument.value

    if type(current_value) == "boolean" then
        current_value = ""
    end

    for _, match in ipairs(matches) do
        for _, value in ipairs(_get_named_option_choices(match, current_value)) do
            if not vim.tbl_contains(output, value) then
                table.insert(output, string.format("--%s=%s", argument.name, value))
            end
        end
    end

    return output
end

--- Convert `argument` into completion option(s).
---
--- @param argument string | string[] | CompletionOption | CompletionOption[]
---     Each argument / option to convert (could be one or several).
--- @return CompletionOption[]
---     The converted options. Even if `argument` was a single item, this
---     function returns a table with at least one element.
---
local function _get_arguments(argument)
    local type_ = type(argument)

    if type_ == "string" then
        return argparse.parse_arguments(argument).arguments
    end

    if vim.isarray(argument) then
        if vim.tbl_isempty(argument) then
            vlog.error("An empty argument was given. Cannot expand for more arguments.")

            return {}
        end

        local output = {}

        for _, argument_ in ipairs(argument) do
            local argument_type = type(argument_)

            if argument_type == "string" then
                for _, parsed_argument in ipairs(argparse.parse_arguments(argument_).arguments) do
                    table.insert(output, parsed_argument)
                end
            elseif argument_type == "table" then
                -- NOTE: This situation should be very rare. Assume that the
                -- user knows what they're doing here.
                --
                table.insert(output, argument_)
            end
        end

        return output
    end

    if type_ == "table" then
        return { argument }
    end

    vlog.fmt_warning('Unable to parse "%s" for more arguments.', argument)

    return {}
end

--- Check if `items` is a flat array/list of string values.
---
--- @param items ... An array to check.
--- @return boolean # If found, return `true`.
---
local function _is_string_list(items)
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
    local function _get_choices(current_value)
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

--- Convert `tree` into a completion tree (if it isn't already).
---
--- @param tree IncompleteOptionTree | ArgumentTree
---     The object to fill out into completion options.
--- @return OptionTree
---     The fully-parsed completion information.
---
local function _fill_missing_data(tree)
    tree = vim.deepcopy(tree)
    --- @cast tree OptionTree

    for index, items in ipairs(tree) do
        items = _get_arguments(items)
        tree[index] = items
    end

    for _, items in ipairs(tree) do
        for _, item in ipairs(items) do
            if item.count == nil then
                item.count = 1
            end

            if item.used == nil then
                item.used = 0
            end

            if item.argument_type == argparse.ArgumentType.position then
                if item.required == nil then
                    item.required = true
                end
            elseif item.argument_type == argparse.ArgumentType.named then
                if item.required == nil then
                    item.required = false
                end

                if item.choices and _is_string_list(item.choices) then
                    --- @diagnostic disable-next-line param-type-mismatch
                    item.choices = _get_startswith_auto_complete_function(item.choices)
                end
            elseif item.argument_type == argparse.ArgumentType.flag then
                if item.required == nil then
                    item.required = false
                end
            end
        end
    end

    return tree
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
        local options = tree[1]

        return _get_auto_complete_values(options or {})
    end

    local stripped = _rstrip_input(input, column)
    local argument = _get_remainder_named_argument(stripped, tree)

    if argument and argument.argument_type == argparse.ArgumentType.named then
        if stripped.remainder.value == "" then
            -- The cursor is on the last argument
            return _get_unfinished_named_argument_auto_complete_options(tree, argument)
        end
    end

    local options, tree_index = _compute_completion_options(tree, stripped)

    if stripped.remainder.value ~= "" then
        return _get_auto_complete_values(options or {})
    end

    local last = stripped.arguments[#stripped.arguments]

    if not last then
        return {}
    end

    local matches = _handle_partial_matches(last, (options or tree[tree_index] or {}))

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

return M
