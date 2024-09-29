local _cmdparse_utility = require("plugin_template._cli._cmdparse_utility")
local cmdparse_constant = require("plugin_template._cli.cmdparse_constant")
local texter = require("plugin_template._core.texter")

local M = {}

-- TODO: docstring
-- TODO: Cleanup

-- --- Get a friendly label for `position`. Used for `--help` flags.
-- ---
-- --- If `position` has expected choices, those choices are returned instead.
-- ---
-- ---@param position cmdparse.Parameter Some (non-flag) parameter to get text for.
-- ---@return string # The found label.
-- ---
-- local function _get_position_long_help_text(position)
--     local text
--
--     if position.value_hint and position.value_hint ~= "" then
--         text = position.value_hint
--     elseif position.choices then
--         text = _get_help_command_labels(position.choices({ contexts = { M.ChoiceContext.help_message } }))
--     else
--         text = position:get_nice_name()
--     end
--
--     if type(position._count) == "string" then
--         text = text .. position._count
--     end
--
--     if position.help then
--         text = text .. "    " .. position.help
--     end
--
--     return text
-- end

-- local function _get_recommended_flag_value_hint(options)
--     local hint
--
--     if not options.choices then
--         hint = _get_recommended_value_hint_name(options.names[1])
--     else
--         local choices = options.choices({ contexts = { M.ChoiceContext.help_message } })
--         hint = "{" .. vim.fn.join(choices, ",") .. "}"
--     end
--
--     if type(options.nargs) == "number" then
--         local items = {}
--
--         for _=1, options.nargs do
--             table.insert(items, hint)
--         end
--
--         return vim.fn.join(items, " ")
--     end
--
--     if options.nargs == _ZERO_OR_MORE then
--         return string.format("[%s ...]", hint)
--     end
--
--     if options.nargs == _ONE_OR_MORE then
--         return string.format("%s [%s ...]", hint, hint)
--     end
--
--     if options.nargs == 0 then
--         return ""
--     end
--
--     return ""
-- end

local function _get_recommended_value_hint_name(text)
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

    return word:upper():gsub("-", "_")
end

local function _get_position_usage_help_text(position)
    local text

    if position.value_hint and position.value_hint ~= "" then
        text = position.value_hint
    elseif position.choices then
        local choices = position.choices({ contexts = { cmdparse_constant.ChoiceContext.help_message } })

        text = "{" .. vim.fn.join(choices, ",") .. "}"
    else
        text = _get_recommended_value_hint_name(position.names[1])
    end

    local nargs = position:get_nargs()

    if type(nargs) == "number" then
        local output = {}

        for _ = 1, nargs do
            table.insert(output, text)
        end

        return vim.fn.join(output, " ")
    end

    if nargs == cmdparse_constant.Counter.zero_or_more then
        return string.format("[%s ...]", text)
    end

    if nargs == cmdparse_constant.Counter.one_or_more then
        return string.format("%s [%s ...]", text, text)
    end

    return text
end

-- local function _get_position_usage_help_text(position)
--     local function _get_continuation_text(token, nargs)
--         if nargs == _ZERO_OR_MORE then
--             return string.format("[%s ...]", token)
--         end
--
--         if nargs == _ONE_OR_MORE then
--             return string.format("%s [%s ...]", token, token)
--         end
--
--         return nil
--     end
--
--     local token = _get_token_text(position)
--
--     return _get_continuation_text(token, position:get_nargs()) or token
-- end

function M.get_flag_help_text(flag)
    local text = _get_position_usage_help_text(flag)

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

--- Get all subcomands (child parsers) from `parser`.
---
---@param parser cmdparse.ParameterParser Some runnable command to get parameters from.
---@return string[] # The labels of all of the flags.
---
function M.get_parser_child_parser_help_text(parser)
    local output = {}

    for parser_ in _cmdparse_utility.iter_parsers(parser) do
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

function M.get_position_description_help_text(position)
    local text = M.get_position_usage_help_text(position)

    if position.help and position.help ~= "" then
        text = text .. "    " .. position.help
    end

    return text
end

function M.get_position_usage_help_text(position)
    local text = _get_position_usage_help_text(position)

    if type(position._count) == "string" then
        text = text .. position._count
    end

    return text
end

return M
