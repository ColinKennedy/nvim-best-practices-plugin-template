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

local function is_char(character)
  return character:match('[^=\'"%s]') ~= nil
end

-- TODO: Change the variable names. They're awful

local function _parse_args(x)
  --- @type string[], table<string,string|boolean>
  local pos_args, named_args = {}, {}

  local last_argument = nil
  local state = 'in_arg'
  local cur_arg = ''
  local cur_val = ''
  local cur_quote = ''

  local function peek(idx)
    return x:sub(idx + 1, idx + 1)
  end

  local i = 1
  while i <= #x do
    local ch = x:sub(i, i)

    if state == 'in_arg' then
      if is_char(ch) then
        if ch == '-' and peek(i) == '-' then
          state = 'in_flag'
          cur_arg = ''
          i = i + 1
        else
          cur_arg = cur_arg .. ch
        end
      elseif ch:match('%s') then
        local position = #pos_args + 1
        last_argument = {
          argument_type = _ArgumentType.positional .. "b",
          data = position,
        }
        pos_args[position] = cur_arg
        state = 'in_ws'
      elseif ch == '=' then
        cur_val = ''
        local next_ch = peek(i)
        if next_ch == "'" or next_ch == '"' then
          cur_quote = next_ch
          i = i + 1
          state = 'in_quote'
        else
          state = 'in_value'
        end
      end
    elseif state == 'in_flag' then
      if ch:match('%s') then
        last_argument = {
          argument_type = _ArgumentType.named,
          data = cur_arg,
        }
        named_args[cur_arg] = true
        state = 'in_ws'
      else
        cur_arg = cur_arg .. ch
      end
    elseif state == 'in_ws' then
      if is_char(ch) then
        if ch == '-' and peek(i) == '-' then
          state = 'in_flag'
          cur_arg = ''
          i = i + 1
        else
          state = 'in_arg'
          cur_arg = ch
        end
      end
    elseif state == 'in_value' then
      if is_char(ch) then
        cur_val = cur_val .. ch
      elseif ch:match('%s') then
        last_argument = {
          argument_type = _ArgumentType.named,
          data = cur_arg,
        }
        named_args[cur_arg] = cur_val
        cur_arg = ''
        state = 'in_ws'
      end
    elseif state == 'in_quote' then
      local next_ch = peek(i)
      if ch == '\\' and next_ch == cur_quote then
        cur_val = cur_val .. next_ch
        i = i + 1
      elseif ch == cur_quote then
        last_argument = {
          argument_type = _ArgumentType.named,
          data = cur_arg,
        }
        named_args[cur_arg] = cur_val
        state = 'in_ws'
        if next_ch ~= '' and not next_ch:match('%s') then
          error('malformed argument: ' .. next_ch)
        end
      else
        cur_val = cur_val .. ch
      end
    end
    i = i + 1
  end

  if #cur_arg > 0 then
    if state == 'in_arg' then
      local position = #pos_args + 1
      last_argument = {
        argument_type = _ArgumentType.positional .. "z",
        data = position,
      }
      pos_args[position] = cur_arg
    elseif state == 'in_flag' then
      last_argument = {
        argument_type = _ArgumentType.named,
        data = cur_arg,
      }
      named_args[cur_arg] = true
    elseif state == 'in_value' then
      last_argument = {
        argument_type = _ArgumentType.named,
        data = cur_arg,
      }
      named_args[cur_arg] = cur_val
    end
  end

  -- TODO: Remove
  -- print('DEBUGPRINT[1]: argparse.lua:148: last_argument=' .. vim.inspect(last_argument))
  return pos_args, named_args, last_argument
end

--- Get all positional arguments and named arguments.
---
--- @param x string
--- @return string[], table<string,string|boolean>
---
function M.parse_args(x)
  local positional_arguments, named_arguments, _ = _parse_args(x)

  return {positional_arguments, named_arguments}
end

return M
