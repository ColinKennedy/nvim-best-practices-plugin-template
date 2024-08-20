-- -- TODO: Move this somewhere more core / to its own Lua package
--
-- local argparse = require("plugin_template._cli.argparse")
-- local tabler = require("plugin_template._core.tabler")
--
-- -- TODO: Get this code working + add docstrings
--
-- --- @class ArgumentTree
-- ---     A basic CLI description that answers. 1. What arguments are next 2.
-- ---     What should we return for auto-complete, if anything.
--
-- local M = {}
--
-- local function _is_empty(text)
--     return text:match("^%s*$") ~= nil
-- end
--
-- local function _is_double_dash_prefix(text)
--     return text:match("^%s*--%s*$") ~= nil
-- end
--
-- local function _is_single_dash_prefix(text)
--     return text:match("^%s*-%s*$") ~= nil
-- end
--
-- local function _get_current_options(tree, index)
--     local current = tree[index]
--     local type_ = type(current)
--
--     if type_ == "string" then
--         return argparse.parse_arguments(current).arguments
--     end
--
--     if vim.isarray(current) then
--         if vim.tbl_isempty(current) then
--             -- TODO: Log error
--             return {}
--         end
--
--         local output = {}
--
--         for _, item in ipairs(current) do
--             local item_type = type(item)
--
--             if item_type == "string" then
--                 for _, parsed_item in ipairs(argparse.parse_arguments(item).arguments) do
--                     table.insert(output, parsed_item)
--                 end
--             elseif item_type == "table" then
--                 -- NOTE: This situation should be very rare. Assume that the
--                 -- user knows what they're doing here.
--                 --
--                 table.insert(output, item)
--             end
--         end
--
--         return output
--     end
--
--     if type_ == "table" then
--         return current
--     end
-- end
--
-- local function _is_exhausted(options)
--     for _, option in ipairs(options) do
--         if type(option.count) == "number" then
--             return option.count < 1
--         elseif option.count == nil then
--             return false
--         end
--     end
--
--     -- TODO: This is probably bugged, currently. Arguments like count = "*"
--     -- will not work with this
--     --
--     return true
-- end
--
-- local function _is_partial_match_named_argument(data, option)
--     if
--         data.argument_type == argparse.ArgumentType.named
--         and data.argument_type == option.argument_type
--         and not _is_exhausted({ option })
--         and option.name ~= data.name
--         and vim.startswith(option.name, data.name)
--     then
--         return true
--     end
--
--     if
--         data.argument_type == argparse.ArgumentType.flag
--         and option.argument_type == argparse.ArgumentType.named
--         and not _is_exhausted({ option })
--         and option.name ~= data.name
--         and vim.startswith(option.name, data.name)
--     then
--         -- NOTE: When we're in the middle of typing `--foo`, we don't know if
--         -- it will end as just `--foo` or if it will become `--foo=bar` so we
--         -- have to assume that it could.
--         --
--         return true
--     end
--
--     return false
-- end
--
-- local function _is_partial_match(data, option)
--     if
--         data.argument_type == argparse.ArgumentType.position
--         and data.argument_type == option.argument_type
--         and not _is_exhausted({ option })
--     then
--         return option.value ~= data.value and vim.startswith(option.value, data.value)
--     end
--
--     if _is_partial_match_named_argument(data, option) then
--         return true
--     end
--
--     return false
-- end
--
-- local function _get_matches(data, options)
--     local output = {}
--
--     for _, option in ipairs(options) do
--         if _is_partial_match(data, option) then
--             table.insert(output, option)
--         end
--     end
--
--     return output
-- end
--
-- local function _has_positional_argument(options)
--     for _, option in ipairs(options) do
--         if option.argument_type == argparse.ArgumentType.position then
--             return true
--         end
--     end
--
--     return false
-- end
--
-- local function _clear_position_argument_counts(options)
--     for _, option in ipairs(options) do
--         if option.argument_type == argparse.ArgumentType.position then
--             option.count = 0
--         end
--     end
-- end
--
-- local function _compute_remaining_counts(all_options, matching_options)
--     if _has_positional_argument(matching_options) then
--         -- NOTE: When a user gives a position argument, it means the user chose
--         -- that argument over any other position argument. So all other
--         -- position arguments must be cleared
--         --
--         _clear_position_argument_counts(all_options)
--     end
--
--     -- NOTE: Clear flags / named arguments as needed
--     for _, option in ipairs(all_options) do
--         if option.count == nil then
--             option.count = 1
--         end
--
--         if type(option.count) == "number" then
--             option.count = option.count - 1
--         end
--     end
-- end
--
-- local function _replace_options(data, options)
--     local replacements = {}
--
--     for _, option in ipairs(options) do
--         if option.argument_type == argparse.ArgumentType.position then
--             table.insert(replacements, option.value)
--         elseif option.argument_type == argparse.ArgumentType.flag then
--             table.insert(replacements, "-" .. option.name)
--         elseif option.argument_type == argparse.ArgumentType.named then
--             table.insert(replacements, "--" .. option.name .. "=")
--         end
--     end
--
--     tabler.clear(data)
--
--     for key, value in pairs(replacements) do
--         data[key] = value
--     end
-- end
--
-- local function _is_user_getting_the_next_input_argument(input)
--     return input.remainder.value == " "
-- end
--
-- local function _get_exact_matches(data, options)
--     local function _is_exact_match(data, option)
--         if
--             data.argument_type == argparse.ArgumentType.position
--             and data.argument_type == option.argument_type
--             and not _is_exhausted({ option })
--         then
--             return option.value == data.value
--         end
--
--         if
--             data.argument_type == argparse.ArgumentType.named
--             and data.argument_type == option.argument_type
--             and not _is_exhausted({ option })
--             and data.value
--         then
--             return option.name == data.name
--         end
--
--         return false
--     end
--
--     local output = {}
--
--     for _, option in ipairs(options) do
--         if _is_exact_match(data, option) then
--             table.insert(output, option)
--         end
--     end
--
--     return output
-- end
--
-- local function _get_double_dash_name(text)
--     return text:match("^%s*--(%w*)%s*$")
-- end
--
-- local function _get_named_argument_choices(argument)
--     if not argument.choices then
--         return {}
--     end
--
--     if type(argument.choices) == "function" then
--         return argument.choices()
--     end
--
--     return argument.choices
-- end
--
-- local function _get_exact_named_argument_option(data, options)
--     for _, option in ipairs(options) do
--         if
--             data.argument_type == argparse.ArgumentType.named
--             and option.argument_type == argparse.ArgumentType.named
--             and not _is_exhausted({ option })
--             and option.name == data.name
--         then
--             return option
--         end
--     end
--
--     return nil
-- end
--
-- --- Get the auto-complete options for the user's `input`.
-- ---
-- --- @param tree ArgumentTree
-- ---     A basic CLI description that answers. 1. What arguments are next 2.
-- ---     What should we return for auto-complete, if anything.
-- --- @param input ArgparseResults
-- ---     The user's parsed text.
-- ---
-- function M.get_options(tree, input)
--     tree = vim.deepcopy(tree) -- NOTE: We may edit `tree` so we make a copy first
--     local tree_index = 1
--     local current_options = _get_current_options(tree, tree_index)
--     local output = {}
--     local arguments_count = #input.arguments
--
--     local function _handle_exact_matches(data, arguments_index)
--         local options = _get_exact_matches(data, current_options)
--
--         if vim.tbl_isempty(options) then
--             return false
--         end
--
--         if arguments_index < arguments_count or _is_user_getting_the_next_input_argument(input) then
--             -- NOTE: We need the next possible argument(s)
--             tree_index = tree_index + 1
--             current_options = _get_current_options(tree, tree_index)
--             _replace_options(output, current_options)
--         else
--             -- NOTE: We reached the end of the command-line call
--             _replace_options(output, {})
--         end
--
--         return true
--     end
--
--     local function _handle_partial_matches(data)
--         local options = _get_matches(data, current_options)
--
--         if vim.tbl_isempty(options) then
--             return false
--         end
--
--         _compute_remaining_counts(current_options, options)
--         _replace_options(output, options)
--
--         if _is_exhausted(current_options) then
--             tree_index = tree_index + 1
--             current_options = _get_current_options(tree, tree_index)
--         end
--
--         return true
--     end
--
--     local function _handle_partial_named_arguments(data, arguments_index)
--         if arguments_index < #input.arguments or _is_user_getting_the_next_input_argument(input) then
--             return false
--         end
--
--         if data.argument_type ~= argparse.ArgumentType.named or data.value ~= false then
--             return false
--         end
--
--         local option = _get_exact_named_argument_option(data, current_options)
--
--         _compute_remaining_counts(current_options, { option })
--
--         tabler.clear(output)
--         tabler.extend(output, _get_named_argument_choices(option))
--
--         return true
--     end
--
--     local function _handle_remainder_matches(input)
--         if _is_empty(input.remainder.value) then
--             return
--         end
--
--         tree_index = tree_index + 1
--         current_options = _get_current_options(tree, tree_index)
--
--         local options = {}
--
--         if _is_single_dash_prefix(input.remainder.value) then
--             -- TODO: Finish this section
--             -- Add a unittest for this case (a remainder that includes just a single dash)
--         end
--
--         if _is_double_dash_prefix(input.remainder.value) then
--             local name = _get_double_dash_name(input.remainder.value)
--
--             for _, option in ipairs(current_options) do
--                 if option.argument_type == argparse.ArgumentType.named and vim.startswith(option.name, name) then
--                     table.insert(options, option)
--                 end
--             end
--         end
--
--         _replace_options(output, options)
--         _compute_remaining_counts(current_options, options)
--     end
--
--     for arguments_index, data in ipairs(input.arguments) do
--         for _, operation in ipairs({ _handle_exact_matches, _handle_partial_matches, _handle_partial_named_arguments }) do
--             if operation(data, arguments_index) then
--                 break
--             end
--         end
--     end
--
--     _handle_remainder_matches(input)
--
--     return output
-- end
--
-- return M

local argparse = require("plugin_template._cli.argparse")
local argparse_helper = require("plugin_template._cli.argparse_helper")

local _INVALID_INDEX = -1

--- @class ArgumentTree
---     A basic CLI description that answers. 1. What arguments are next 2.
---     What should we return for auto-complete, if anything.

local M = {}

--- Check if `options` has any count-enabled arguments that still have usages left.
---
--- @param options (FlagArgument | PositionArgument | NamedArgument)[]
--- @return boolean # All of `options` don't have any counts left.
---
local function _is_exhausted(options)
    -- TODO: Fix the missing count arguments later
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

--- Convert options class instances into raw auto-completion text.
---
--- @param options (FlagArgument | PositionArgument | NamedArgument)[]
---     All arguments to extract for auto-completion text.
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
---     The starting point for the argument. Must be a 1-or-greater value.
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

--- Get all of the arguments starting at `index` which can be used for auto-completion.
---
--- @param tree ArgumentTree
---     A basic CLI description that answers. 1. What arguments are next 2.
---     What should we return for auto-complete, if anything.
--- @param index number
---     The starting point to look within for auto-completion options.
--- @return (FlagArgument | PositionArgument | NamedArgument)[]
---     The arguments to consider for auto-completion.
---
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

    return {}
end

--- Check if `data` is a fully-filled-out argument and also found in `options`.
---
--- @param data (FlagArgument | PositionArgument | NamedArgument)[]
---     An argument that may be fully-filled-out or might be partially written
---     by a user. If it is partially written, it is not included in the return.
--- @param options (FlagArgument | PositionArgument | NamedArgument)[]
---     All possible argument tree options (fully-filled-out).
--- @return (FlagArgument | PositionArgument | NamedArgument)[]
---     All `options` that match `data`.
---
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

--- Check if `options` has at least one position argument.
---
--- @param options (FlagArgument | PositionArgument | NamedArgument)[]
--- @return boolean # Return `true` if there's at least one position argument found.
---
local function _has_positional_argument(options)
    for _, option in ipairs(options) do
        if option.argument_type == argparse.ArgumentType.position then
            return true
        end
    end

    return false
end

--- Decrement all `option.count` values of `options`.
---
--- Only call this function after a position argument has been used.
---
--- @param options (FlagArgument | PositionArgument | NamedArgument)[]
---
local function _clear_position_argument_counts(options)
    for _, option in ipairs(options) do
        if option.argument_type == argparse.ArgumentType.position then
            option.count = 0
        end
    end
end

--- Decrement all `option.count` values of `all_options`.
---
--- @param all_options (FlagArgument | PositionArgument | NamedArgument)[]
---     All options that were auto-completion candidates but did not match.
--- @param matching_options (FlagArgument | PositionArgument | NamedArgument)[]
---     All options that matched as auto-completion candidates.
---
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

--- @param tree ArgumentTree
---     A basic CLI description that answers. 1. What arguments are next 2.
---     What should we return for auto-complete, if anything.
--- @param input ArgparseResults
---     The user's parsed text.
--- @return (FlagArgument | PositionArgument | NamedArgument)[]
---     The arguments to consider for auto-completion.
--- @return number
---     The starting point of the argument "tree" used to gather the arguments.
---
local function _compute_completion_options(tree, input)
    local all_but_last_argument = #input.arguments
    local tree_index = 1
    --- @type (FlagArgument | PositionArgument | NamedArgument)[]?
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
            return {}, _INVALID_INDEX
        end

        _compute_remaining_counts(current_options, matches)

        if _is_exhausted(current_options) then
            -- NOTE: need to get more options
            tree_index = tree_index + 1
            current_options = _get_current_options(tree, tree_index)
        end
    end

    return (current_options or {}), tree_index
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
--- @param tree ArgumentTree
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
    local stripped = argparse_helper.rstrip_arguments(
        input,
        _get_cursor_offset(input, column)
    )

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

    -- TODO: Finish
    local last = stripped.arguments[#stripped.arguments]
    local matches = _get_exact_matches(last, options)

    return _get_auto_complete_values(options)

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
