--- Parse text into positional / named arguments.
---
--- @module 'plugin_name._cli.argparse'
---

-- TODO: Docstrings. Add
-- https://github.com/lewis6991/gitsigns.nvim/blob/562dc47189ad3c8696dbf460d38603a74d544849/lua/gitsigns/cli/argparse.lua#L10

-- TODO: Add NOTE where needed

local M = {}

local _State = {
    argument_start = "argument_start",
    normal = "normal",
    in_double_flag = "in_double_flag",
    in_single_flag = "in_single_flag",
    in_quote = "in_quote",
    in_value = "in_value",
}

--- Check if `character` is a typical a-zA-Z0-9 character.
---
--- @param character string Basically any non-special character.
--- @return boolean # If a-zA-Z0-9, return `true`.
---
local function is_alpha_numeric(character)
    return character:match("[^='\"%s]") ~= nil
end

--- Check if `text` is a space, tab, or newline.
---
--- @param character string Basically `" "`, `\n`, `\t`.
--- @return boolean # If it's any whitespace, return `true`.
---
local function _is_whitespace(character)
    return character:match("%s")
end

--- Check if `character` starts a multi-word quote.
---
--- @param character string Basically ' or ".
--- @return boolean # If ' or ", return `true`.
---
local function _is_quote(character)
    return character == '"' or character == "'"
end

--- Parse for positional arguments, named arguments, and flag arguments.
---
--- In a command like `bar -f --buzz --some="thing else"`...
---     - `bar` is positional
---     - `-f` is a single-letter flag
---     - `--buzz` is a multi-letter flag
---     - `--some="thing else" is a named argument whose value is "thing else"
---
--- @param whole_text string
---     Some command to parse. e.g. `bar -f --buzz --some="thing else"`.
--- @return string[], table<string, string | boolean>
---     All found for positional arguments, named arguments, and flag arguments.
---
local function _parse_args(whole_text)
    --- @type string[], table<string, string | boolean>
    local position_arguments, named_arguments = {}, {}

    local state = _State.argument_start
    local current_argument = ""
    local current_name = ""
    local is_escaping = false
    local needs_name = false
    local needs_value = false

    local function peek(index)
        return whole_text:sub(index + 1, index + 1)
    end

    local function _add_to_output()
        -- We reached the end of the quote
        if needs_value then
            named_arguments[current_name] = current_argument
        else
            table.insert(position_arguments, current_argument)
        end
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

    local index = 1

    while index <= #whole_text do
        local character = whole_text:sub(index, index)

        local function _append_to_wip_argument(alternate_character)
            current_argument = current_argument .. (alternate_character or character)
        end

        if character == "\\" then
            is_escaping = not is_escaping
        end

        if state == _State.argument_start then
            if is_alpha_numeric(character) then
                -- We know we've encounted some -f` or `--foo` or `--foo=bar` but we
                -- aren't sure which it is yet.
                --
                if character == "-" then
                    if peek(index) == "-" then
                        -- NOTE: It's definitely a `--foo` flag or `--foo=bar` argument.
                        state = _State.in_double_flag
                        _reset_argument()
                        index = index + 1
                        needs_name = true
                        needs_value = true
                    else
                        -- NOTE: It's definitely a `-f` flag.
                        state = _State.in_single_flag
                        _reset_argument()
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
            -- NOTE: We're inside of some thing. e.g. `"foo -b thing"!
            if not is_escaping and _is_quote(character) then
                -- NOTE: We've reached the end of the quote
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
                current_name = current_argument
                _reset_argument()

                if _is_quote(peek(index)) then
                    -- NOTE: We've discovered a `--foo="bar thing"` argument and we're just about
                    -- to find the `"bar thing"` part
                    --
                    state = _State.in_quote
                    index = index + 1
                else
                    state = _State.normal
                end
            elseif _is_whitespace(character) then
                -- NOTE: Ignore whitespace in some situations.
                if not is_escaping then
                    current_name = current_argument
                    current_argument = true
                    _add_to_output()
                    _reset_all()
                end
            elseif needs_name then
                _append_to_wip_argument()
            end
        elseif state == _State.in_single_flag then
            if _is_whitespace(character) then
                -- We've reached the end of 1+ single flag(s).
                -- Add every found character as flags
                --
                local current_argument_ = current_argument
                current_argument = true

                for index_ = 1, #current_argument_ do
                    local character_ = current_argument_:sub(index_, index_)
                    current_name = character_
                    _add_to_output()
                end

                _reset_all()
            else
                _append_to_wip_argument()
            end
        elseif state == _State.normal then
            if is_escaping then
                local next = peek(index)
                _append_to_wip_argument(next)
            elseif _is_whitespace(character) then
                _add_to_output()
                _reset_all()
            else
                _append_to_wip_argument()
            end
        end

        index = index + 1
    end

    if state == _State.normal and current_argument ~= "" then
        _add_to_output()
    elseif (state == _State.in_double_flag or state == _State.in_single_flag) and current_argument ~= "" then
        current_name = current_argument
        current_argument = true
        needs_value = true
        _add_to_output()
    end

    return { position_arguments, named_arguments }
end

--- Get all positional arguments and named arguments.
---
--- @param whole_text string
---     Some command to parse. e.g. `bar -f --buzz --some="thing else"`.
--- @return string[], table<string, string | boolean>
---     All found for positional arguments, named arguments, and flag arguments.
---
function M.parse_args(whole_text)
    return _parse_args(whole_text)
end

return M
