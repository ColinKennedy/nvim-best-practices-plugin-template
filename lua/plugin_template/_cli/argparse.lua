--- Parse text into positional / named arguments.
---
---@module 'plugin_template._cli.argparse'
---

local vlog = require("plugin_template._vendors.vlog")

local M = {}

M.PREFIX_CHARACTERS = { "-", "+" }

---@enum argparse.ArgumentType
M.ArgumentType = {
    flag = "__flag",
    named = "__named",
    position = "__position",
}

---@class argparse.BaseArgument
---    A base class to inherit from.
---@field argument_type argparse.ArgumentType
---    An type indicator for this argument.
---@field range argparse.ArgumentRange
---    The start and end index (both are inclusive) of the argument.

---@class argparse.ArgumentRange
---    The start and end index (both are inclusive) of the argument.
---@field start_column number
---    The first index of the argument (inclusive).
---@field end_column number
---    The last index of the argument (inclusive).

---@class argparse.FlagArgument : argparse.BaseArgument
---    An argument that has a name but no value. It starts with either - or --
---    Examples: `-f` or `--foo` or `--foo-bar`
---@field name string
---    The text of the flag. e.g. The `"foo"` part of `"--foo"`.

---@class argparse.PositionArgument : argparse.BaseArgument
---    An argument that is just text. e.g. `"foo bar"` is two positions, foo and bar.
---@field value string
---    The position's label.

---@class argparse.NamedArgument : argparse.FlagArgument
---    A --key=value pair. Basically it's a argparse.FlagArgument that has an extra value.
---@field value string | boolean
---    The second-hand side of the argument. e.g. The `"bar"` part of
---    `"--foo=bar"`. If the argument is partially written like `"--foo="`
---    then this will be an empty string.

---@alias argparse.Argument argparse.FlagArgument | argparse.PositionArgument | argparse.NamedArgument

---@class argparse.Results
---    All information that was found from parsing some user's input.
---@field arguments argparse.Argument[]
---    The arguments that were able to be parsed
---@field remainder argparse.Remainder
---    Any leftover text during parsing that didn't match an argument.
---@field text string
---    The original, raw, unparsed user arguments.

---@class argparse.Remainder
---    Any leftover text during parsing that didn't match an argument.
---@field value string
---    The raw, unparsed text.

--- An internal tracker for the arguments.
local _State = {
    argument_start = "argument_start",
    in_double_flag = "in_double_flag",
    in_quote = "in_quote",
    in_single_flag = "in_single_flag",
    in_value = "in_value",
    normal = "normal",
    value_is_pending = "values_is_pending",
}

--- Check if `character` is a typical a-zA-Z0-9 character.
---
---@param character string Basically any non-special character.
---@return boolean # If a-zA-Z0-9, return `true`.
---
local function is_alpha_numeric(character)
    return character:match("[^='\"%s]") ~= nil
end

--- Check if `character` marks the start of a `argparse.FlagArgument` or `argparse.NamedArgument`.
---
---@param character string A starting character. e.g. `-`, `+`, etc.
---@return boolean # If `character` is a `argparse.PositionArgument` character, return `true`.
---
local function _is_prefix(character)
    return vim.tbl_contains(M.PREFIX_CHARACTERS, character)
end

--- Check if `character` is a space, tab, or newline.
---
---@param character string Basically `" "`, `\n`, `\t`.
---@return boolean # If it's any whitespace, return `true`.
---
local function _is_whitespace(character)
    return character:match("%s")
end

--- Check if `character` starts a multi-word quote.
---
---@param character string Basically ' or ".
---@return boolean # If ' or ", return `true`.
---
local function _is_quote(character)
    return character == '"' or character == "'"
end

--- Parse for positional arguments, named arguments, and flag arguments.
---
--- In a command like `bar -f --buzz --some="thing else"`...
---    - `bar` is positional
---    - `-f` is a single-letter flag
---    - `--buzz` is a multi-letter flag
---    - `--some="thing else" is a named argument whose value is "thing else"
---
---@param text string
---    Some command to parse. e.g. `bar -f --buzz --some="thing else"`.
---@return argparse.Results
---    All found for positional arguments, named arguments, and flag arguments.
---
function M.parse_arguments(text)
    local output = {}

    local state = _State.argument_start
    --- @type string | boolean
    local current_argument = ""
    --- @type string | boolean
    local current_name = ""
    local is_escaping = false
    local needs_name = false
    local needs_value = false
    --- @type argparse.Remainder
    local remainder = { value = "" }
    local start_index = 1
    local escaped_character_count = 0

    local physical_index = 1

    --- Look ahead to the next character in `text`.
    ---
    --- @param index number A 1-or-more value to check.
    --- @return string # The found character, if any.
    ---
    local function peek(index)
        return text:sub(index + 1, index + 1)
    end

    local logical_index = physical_index

    --- Adds any accumulated argument data to the final output.
    ---
    --- Any buffered / remainder text is cleared.
    ---
    local function _add_to_output()
        remainder.value = ""
        local end_index = physical_index - escaped_character_count - 1
        local range = { start_column = start_index, end_column = end_index }

        if not needs_value then
            table.insert(output, {
                argument_type = M.ArgumentType.position,
                range = range,
                value = current_argument,
            })

            return
        end

        if current_argument == true then
            table.insert(output, {
                argument_type = M.ArgumentType.flag,
                name = current_name,
                range = range,
            })

            return
        end

        table.insert(output, {
            argument_type = M.ArgumentType.named,
            name = current_name,
            range = range,
            value = current_argument,
        })
    end

    local function _reset_argument()
        current_argument = ""
    end

    local function _reset_all()
        _reset_argument()
        current_name = ""
        is_escaping = false
        needs_name = false
        needs_value = false
        state = _State.argument_start
    end

    while physical_index <= #text do
        local character = text:sub(physical_index, physical_index)
        remainder.value = remainder.value .. character

        local function _append_to_wip_argument(alternate_character)
            current_argument = current_argument .. (alternate_character or character)
        end

        if character == "\\" then
            is_escaping = true
        end

        if state == _State.argument_start then
            start_index = logical_index

            if is_alpha_numeric(character) then
                -- NOTE: We know we've encounted some -f` or `--foo` or
                -- `--foo=bar` but we aren't sure which it is yet.
                --
                if _is_prefix(character) then
                    local next_character = peek(physical_index)

                    if _is_prefix(next_character) and next_character == character then
                        -- NOTE: It's definitely a `--foo` flag or `--foo=bar` argument.
                        state = _State.in_double_flag
                        _reset_argument()
                        current_name = character .. next_character
                        remainder.value = remainder.value .. next_character
                        logical_index = logical_index + 1
                        physical_index = physical_index + 1
                        needs_name = true
                        needs_value = true
                    else
                        -- NOTE: It's definitely a `-f` flag.
                        state = _State.in_single_flag
                        _reset_argument()
                        current_name = character
                        needs_name = false
                        needs_value = true
                    end
                elseif _is_quote(character) then
                    -- NOTE: Actually we're inside of some thing. e.g. `"foo -b thing"!
                    state = _State.in_quote
                    needs_value = false
                else
                    state = _State.normal
                    _append_to_wip_argument()
                    needs_value = false
                end
            elseif _is_quote(character) then
                state = _State.in_quote
            end
        elseif state == _State.in_quote then
            -- NOTE: We're inside of some grouped text. e.g. `"foo -b thing"`
            -- is not treated as position text + a flag + position but just as
            -- "some text within quotes".
            --
            if not is_escaping and _is_quote(character) then
                -- NOTE: We've reached the end of the quote
                physical_index = physical_index + 1
                logical_index = logical_index + 1
                _add_to_output()
                _reset_all()
            else
                _append_to_wip_argument()
            end
        elseif state == _State.in_double_flag then
            if character == "=" then
                -- NOTE: We've discovered a `--foo=bar` argument and we're just about
                -- to find the `bar` part
                --
                needs_name = false
                current_name = current_name .. current_argument
                _reset_argument()

                if _is_quote(peek(physical_index)) then
                    -- NOTE: We've discovered a `--foo="bar thing"` argument
                    -- and we're just about to find the `"bar thing"` part
                    --
                    state = _State.in_quote
                    physical_index = physical_index + 1
                    logical_index = logical_index + 1
                else
                    state = _State.value_is_pending
                end
            elseif _is_whitespace(character) then
                -- NOTE: Ignore whitespace in some situations.
                if not is_escaping then
                    current_name = current_name .. current_argument
                    current_argument = true
                    _add_to_output()
                    _reset_all()
                end
            elseif needs_name then
                _append_to_wip_argument()
            end
        elseif state == _State.in_single_flag then
            -- NOTE: Since single-flags can be appended together like `"-abc"`
            -- or "-zzz", we need some special logic to keep track of every flag.
            --
            local next_character = peek(physical_index)

            if _is_whitespace(next_character) or next_character == "" then
                -- NOTE: We've reached the end of 1+ single flag(s).
                -- Add every found character as flags
                --
                local current_argument_ = current_argument .. character
                local current_name_ = current_name
                current_argument = true

                start_index = start_index - 1

                for index_ = 1, #current_argument_ do
                    local character_ = current_argument_:sub(index_, index_)
                    start_index = start_index + 1
                    current_name = current_name_ .. character_
                    physical_index = physical_index + 1
                    _add_to_output()
                    physical_index = physical_index - 1
                end

                _reset_all()
            else
                _append_to_wip_argument()
            end
        elseif state == _State.value_is_pending then
            if _is_whitespace(character) then
                if current_argument == "" then
                    current_argument = false
                end
                _add_to_output()
                _reset_all()
            else
                _append_to_wip_argument()
            end
        elseif state == _State.normal then
            if is_escaping then
                local next = peek(physical_index)
                _append_to_wip_argument(next)
                physical_index = physical_index + 1
                escaped_character_count = escaped_character_count + 1
                is_escaping = false -- NOTE: The escaped character was consumed
            elseif _is_whitespace(character) then
                _add_to_output()
                _reset_all()
                remainder.value = remainder.value .. character
            else
                _append_to_wip_argument()
            end
        end

        logical_index = logical_index + 1
        physical_index = physical_index + 1
    end

    if state == _State.value_is_pending then
        if current_argument == "" then
            current_argument = false
        end

        _add_to_output()
        _reset_all()
    elseif state == _State.normal and current_argument ~= "" then
        _add_to_output()
    elseif (state == _State.in_double_flag or state == _State.in_single_flag) and current_argument ~= "" then
        current_name = current_name .. current_argument
        current_argument = true
        needs_value = true
        _add_to_output()
    end

    vlog.fmt_debug('Got "%s" arguments.', { arguments = output, text = text, remainder = remainder })

    return { arguments = output, text = text, remainder = remainder }
end

return M
