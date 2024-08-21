local argparse = require("plugin_template._cli.argparse")
local argparse_helper = require("plugin_template._cli.argparse_helper")

-- TODO: Add docstrings

--- @class FlagOption : FlagArgument
---     An argument that has a name but no value. It starts with either - or --
---     Examples: `-f` or `--foo` or `--foo-bar`
--- @field used number
---     The number of times that this option has been used already (0-or-greater value).
--- @field count OptionCount
---     The number of times that this option can be used.

--- @class NamedOption : NamedArgument
---     A --key=value pair. Basically it's a FlagArgument that has an extra value.
--- @field used number
---     The number of times that this option has been used already (0-or-greater value).
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

local function _has_fixed_count(option)
    return type(option.count) == "number"
end

local function _has_uses_left(option)
    return option.used < option.count
end

--- Check if `options` has any count-enabled arguments that still have usages left.
---
--- @param options CompletionOption[]
--- @return boolean # All of `options` don't have any counts left.
---
local function _is_exhausted(options)
    for _, option in ipairs(options) do
        if _has_fixed_count(option) and not _has_uses_left(option) then
            return true
        end
    end

    return false
end

local function _is_unfinished_named_argument(data)
    if
        data.argument_type == argparse.ArgumentType.named
        and data.value == false
    then
        return true
    end

    return false
end

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

--- Get all of the options starting at `index` which can be used for auto-completion.
---
--- @param tree OptionTree
---     A basic CLI description that answers. 1. What arguments are next 2.
---     What should we return for auto-complete, if anything.
--- @param index number
---     The starting point to look within for auto-completion options.
--- @return CompletionOption[]
---     The options to consider for auto-completion.
---
local function _get_current_options(tree, index)
    -- TODO: Make this function real, later
    return tree[index]
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
    local function _is_exact_match(data, option)
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

    if require_value == nil then
        require_value = true
    end

    local output = {}

    for _, option in ipairs(options) do
        if _is_exact_match(data, option) then
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

local function _get_argument_name(option)
    if option.argument_type == argparse.ArgumentType.position then
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

local function _get_matches(data, options)
    local output = {}

    for _, option in ipairs(options) do
        if _is_partial_match(data, option) then
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

local function _handle_partial_matches(data, current_options)
    local options = _get_matches(data, current_options)

    if vim.tbl_isempty(options) then
        return {}
    end

    _increment_used(current_options, options)

    return options
end

local function _needs_next_options(options)
    for _, option in ipairs(options) do
        if option.required and _has_fixed_count(option) and _has_uses_left(option) then
            return false
        end
    end

    return true
end

local function _trim_exhausted_options(options)
    local output = {}

    for _, option in ipairs(options) do
        if option.argument_type ~= argparse.ArgumentType.position and not _is_exhausted({option}) then
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
    -- TODO: This variable name is wrong. Change it later
    local all_but_last_argument = #input.arguments
    local tree_index = 1

    --- @type CompletionOption[]?
    local current_options = nil

    for index=1, all_but_last_argument do
        if not current_options then
            current_options = _get_current_options(tree, tree_index)
        end

        local argument = input.arguments[index]
        local matches = _get_exact_matches(argument, current_options)

        if vim.tbl_isempty(matches) then
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
            vim.list_extend(current_options, _get_current_options(tree, tree_index) or {})
        end
    end

    return current_options, tree_index
end

local function _rstrip_input(input, column)
    local stripped = argparse_helper.rstrip_arguments(
        input,
        _get_cursor_offset(input, column)
    )

    local last = stripped.arguments[#stripped.arguments]

    if last then
        stripped.remainder.value = input.text:sub(last.range.end_column + 1, #input.text)
    end

    stripped.text = input.text:sub(1, column)

    return stripped
end

local function _get_unfinished_named_argument_data(input)
    local last = input.arguments[#input.arguments] or {}

    if _is_unfinished_named_argument(last) then
        return last
    end

    return nil
end

-- local function _get_remainder_argument(input)
--     local text = input.remainder.value
-- end

local function _get_named_option_choices(option)
    if not option.choices then
        return {}
    end

    if type(option.choices) == "function" then
        return option.choices()
    end

    return option.choices
end

local function _get_unfinished_named_argument_auto_complete_options(tree, argument)
    -- TODO: Get these options more intelligently. This section needs to consider
    -- flags that are `count="*"` because they could also be options
    --
    local options = tree[#tree]
    local matches = _get_exact_matches(argument, options, false)

    local output = {}

    for _, match in ipairs(matches) do
        local values = _get_named_option_choices(match)

        for _, value in ipairs(values)
        do
            if not vim.tbl_contains(output, value) then
                table.insert(output, value)
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
            -- TODO: Log error
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
        return argument
    end

    -- TODO: Log error
    return {}
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

    for index, items in ipairs(tree)
    do
        items = _get_arguments(items)
        tree[index] = items
    end

    for _, items in ipairs(tree)
    do
        for _, item in ipairs(items)
        do
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
            elseif (
                item.argument_type == argparse.ArgumentType.named
                or item.argument_type == argparse.ArgumentType.flag
            )
            then
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
function M.get_options(tree, input, column)
    -- TODO: Check every section in this function. Do I need all of these?
    tree = _fill_missing_data(tree)

    local stripped = _rstrip_input(input, column)
    local argument = _get_unfinished_named_argument_data(stripped)

    if argument then
        return _get_unfinished_named_argument_auto_complete_options(tree, argument)
    end

    local options, tree_index = _compute_completion_options(tree, stripped)

    -- if column >= input.arguments[#input.arguments].range.end_column then
    --     if input.remainder.value == "" then
    --         -- We must be on the last argument. Let's find out if it is a partial match.
    --         local matches = _get_exact_matches(last, options)
    --
    --         if not vim.tbl_isempty(matches) then
    --             return {}
    --         end
    --     end
    -- end

    -- -- -- TODO: Finish
    -- local last = stripped.arguments[#stripped.arguments]
    -- local matches = _get_exact_matches(last, options or {})
    --
    -- if not vim.tbl_isempty(matches) then
    --     return _get_auto_complete_values(matches)
    -- end

    -- TODO: Figure out if I actually need this. If not, remove it
    -- if column > input.arguments[#input.arguments].range.end_column then
    --     local last = stripped.arguments[#stripped.arguments]
    --     local next = input.arguments[#stripped.arguments + 1]
    --
    --     return _get_auto_complete_values((options or _get_current_options(tree, tree_index)))
    -- end

    if stripped.remainder.value ~= "" then
        return _get_auto_complete_values(options or {})
    end

    local last = stripped.arguments[#stripped.arguments]

    if not last then
        return {}
    end

    local matches = _handle_partial_matches(
        last,
        (options or _get_current_options(tree, tree_index) or {})
    )

    return _get_auto_complete_values(matches)

    -- -- TODO: Handle this
    -- if vim.tbl_isempty(matches) then
    --     -- NOTE: Check for partial matches
    --     return
    -- end
    --
    -- if column == #input then
    --     -- TODO: Do "remainder" logic here, if needed
    -- end
end

return M
