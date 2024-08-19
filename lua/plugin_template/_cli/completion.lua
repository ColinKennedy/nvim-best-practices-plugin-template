-- TODO: Move this somewhere more core / to its own Lua package

local argparse = require("plugin_template._cli.argparse")
local tabler = require("plugin_template._core.tabler")

-- TODO: Get this code working + add docstrings

--- @class ArgumentTree
---     A basic CLI description that answers. 1. What arguments are next 2.
---     What should we return for auto-complete, if anything.

local M = {}

local function _is_empty(text)
    return text:match("^%s*$") ~= nil
end

local function _is_double_dash_prefix(text)
    return text:match("^%s*--%s*$") ~= nil
end

local function _is_single_dash_prefix(text)
    return text:match("^%s*-%s*$") ~= nil
end

local function _get_current_options(tree, index)
    local current = tree[index]
    local type_ = type(current)

    if type_ == "string" then
        return argparse.parse_arguments(current).arguments
    end

    if vim.isarray(current) then
        if vim.tbl_isempty(current) then
            -- TODO: Log error
            return {}
        end

        local output = {}

        for _, item in ipairs(current) do
            local item_type = type(item)

            if item_type == "string" then
                for _, parsed_item in ipairs(argparse.parse_arguments(item).arguments) do
                    table.insert(output, parsed_item)
                end
            elseif item_type == "table" then
                -- NOTE: This situation should be very rare. Assume that the
                -- user knows what they're doing here.
                --
                table.insert(output, item)
            end
        end

        return output
    end

    if type_ == "table" then
        return current
    end
end

local function _is_exhausted(options)
    for _, option in ipairs(options) do
        if type(option.count) == "number" then
            return option.count < 1
        elseif option.count == nil then
            return false
        end
    end

    -- TODO: This is probably bugged, currently. Arguments like count = "*"
    -- will not work with this
    --
    return true
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

local function _get_matches(data, options)
    local output = {}

    for _, option in ipairs(options) do
        if _is_partial_match(data, option) then
            table.insert(output, option)
        end
    end

    return output
end

local function _has_positional_argument(options)
    for _, option in ipairs(options) do
        if option.argument_type == argparse.ArgumentType.position then
            return true
        end
    end

    return false
end

local function _clear_position_argument_counts(options)
    for _, option in ipairs(options) do
        if option.argument_type == argparse.ArgumentType.position then
            option.count = 0
        end
    end
end

local function _compute_remaining_counts(all_options, matching_options)
    if _has_positional_argument(matching_options) then
        -- NOTE: When a user gives a position argument, it means the user chose
        -- that argument over any other position argument. So all other
        -- position arguments must be cleared
        --
        _clear_position_argument_counts(all_options)
    end

    -- NOTE: Clear flags / named arguments as needed
    for _, option in ipairs(all_options) do
        if option.count == nil then
            option.count = 1
        end

        if type(option.count) == "number" then
            option.count = option.count - 1
        end
    end
end

local function _replace_options(data, options)
    local replacements = {}

    for _, option in ipairs(options) do
        if option.argument_type == argparse.ArgumentType.position then
            table.insert(replacements, option.value)
        elseif option.argument_type == argparse.ArgumentType.flag then
            table.insert(replacements, "-" .. option.name)
        elseif option.argument_type == argparse.ArgumentType.named then
            table.insert(replacements, "--" .. option.name .. "=")
        end
    end

    tabler.clear(data)

    for key, value in pairs(replacements) do
        data[key] = value
    end
end

local function _is_user_getting_the_next_input_argument(input)
    return input.remainder.value == " "
end

local function _get_exact_matches(data, options)
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
            and data.value
        then
            return option.name == data.name
        end

        return false
    end

    local output = {}

    for _, option in ipairs(options) do
        if _is_exact_match(data, option) then
            table.insert(output, option)
        end
    end

    return output
end

local function _get_double_dash_name(text)
    return text:match("^%s*--(%w*)%s*$")
end

local function _get_named_argument_choices(argument)
    if not argument.choices then
        return {}
    end

    if type(argument.choices) == "function" then
        return argument.choices()
    end

    return argument.choices
end

local function _get_exact_named_argument_option(data, options)
    for _, option in ipairs(options) do
        if
            data.argument_type == argparse.ArgumentType.named
            and option.argument_type == argparse.ArgumentType.named
            and not _is_exhausted({ option })
            and option.name == data.name
        then
            return option
        end
    end

    return nil
end

--- Get the auto-complete options for the user's `input`.
---
--- @param tree ArgumentTree
---     A basic CLI description that answers. 1. What arguments are next 2.
---     What should we return for auto-complete, if anything.
--- @param input ArgparseResults
---     The user's parsed text.
---
function M.get_options(tree, input)
    tree = vim.deepcopy(tree) -- NOTE: We may edit `tree` so we make a copy first
    local tree_index = 1
    local current_options = _get_current_options(tree, tree_index)
    local output = {}
    local arguments_count = #input.arguments

    local function _handle_exact_matches(data, arguments_index)
        local options = _get_exact_matches(data, current_options)

        if vim.tbl_isempty(options) then
            return false
        end

        if arguments_index < arguments_count or _is_user_getting_the_next_input_argument(input) then
            -- NOTE: We need the next possible argument(s)
            tree_index = tree_index + 1
            current_options = _get_current_options(tree, tree_index)
            _replace_options(output, current_options)
        else
            -- NOTE: We reached the end of the command-line call
            _replace_options(output, {})
        end

        return true
    end

    local function _handle_partial_matches(data)
        local options = _get_matches(data, current_options)

        if vim.tbl_isempty(options) then
            return false
        end

        _compute_remaining_counts(current_options, options)
        _replace_options(output, options)

        if _is_exhausted(current_options) then
            tree_index = tree_index + 1
            current_options = _get_current_options(tree, tree_index)
        end

        return true
    end

    local function _handle_partial_named_arguments(data, arguments_index)
        if arguments_index < #input.arguments or _is_user_getting_the_next_input_argument(input) then
            return false
        end

        if data.argument_type ~= argparse.ArgumentType.named or data.value ~= false then
            return false
        end

        local option = _get_exact_named_argument_option(data, current_options)

        _compute_remaining_counts(current_options, { option })

        tabler.clear(output)
        tabler.extend(output, _get_named_argument_choices(option))

        return true
    end

    local function _handle_remainder_matches(input)
        if _is_empty(input.remainder.value) then
            return
        end

        tree_index = tree_index + 1
        current_options = _get_current_options(tree, tree_index)

        local options = {}

        if _is_single_dash_prefix(input.remainder.value) then
            -- TODO: Finish this section
            -- Add a unittest for this case (a remainder that includes just a single dash)
        end

        if _is_double_dash_prefix(input.remainder.value) then
            local name = _get_double_dash_name(input.remainder.value)

            for _, option in ipairs(current_options) do
                if option.argument_type == argparse.ArgumentType.named and vim.startswith(option.name, name) then
                    table.insert(options, option)
                end
            end
        end

        _replace_options(output, options)
        _compute_remaining_counts(current_options, options)
    end

    for arguments_index, data in ipairs(input.arguments) do
        for _, operation in ipairs({ _handle_exact_matches, _handle_partial_matches, _handle_partial_named_arguments }) do
            if operation(data, arguments_index) then
                break
            end
        end
    end

    _handle_remainder_matches(input)

    return output
end

return M
