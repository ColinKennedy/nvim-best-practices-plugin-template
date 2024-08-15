--- Parse text into positional / named arguments.
---
--- @module 'plugin_name._cli.argparse'
---

-- TODO: Docstrings. Add
-- https://github.com/lewis6991/gitsigns.nvim/blob/562dc47189ad3c8696dbf460d38603a74d544849/lua/gitsigns/cli/argparse.lua#L10


local M = {}

local _ArgumentType = {
  named = "positional",
  positional = "positional",
}

local _State = {
  argument_start = "argument_start",
  normal = "normal",
  in_flag = "in_flag",
  in_quote = "in_quote",
  in_value = "in_value",
}

local function is_alpha_numeric(character)
  return character:match('[^=\'"%s]') ~= nil
end

local function _is_whitespace(next)
  return next:match("%s")
end

local function _is_quote(character)
  return character == '"' or character == "'"
end

-- TODO: Change the variable names. They're awful

local function _parse_args(whole_text)
  --- @type string[], table<string,string|boolean>
  local position_arguments, named_arguments = {}, {}

  local state = _State.argument_start
  local current_argument = ''
  local current_name = ''
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
        if character == '-' and peek(index) == '-' then
          state = _State.in_flag
          _reset_argument()
          index = index + 1
          needs_name = true
          needs_value = true
        elseif _is_quote(character) then
          state = _State.in_quote
          needs_value = false
        else
          state = _State.normal
          _append_to_wip_argument()
          needs_value = false
        end
      end
    elseif state == _State.in_quote then
      if not is_escaping and _is_quote(character) then
        _add_to_output()
        _reset_all()
      else
        _append_to_wip_argument()
      end
    elseif state == _State.in_flag then
      if character == "=" then
        needs_name = false
        current_name = current_argument
        _reset_argument()

        if _is_quote(peek(index)) then
          state = _State.in_quote
          index = index + 1
        else
          state = _State.normal
        end
      elseif _is_whitespace(character) then
        current_name = current_argument
        current_argument = true
        _add_to_output()
        _reset_all()
      elseif needs_name then
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
  end

  return {position_arguments, named_arguments}
end

--- Get all positional arguments and named arguments.
---
--- @param whole_text string
--- @return string[], table<string,string|boolean>
---
function M.parse_args(whole_text)
  return _parse_args(whole_text)
end

return M
