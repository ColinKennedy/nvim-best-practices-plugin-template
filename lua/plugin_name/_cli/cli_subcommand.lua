--- Connect Neovim's COMMAND mode to our Lua functions.
---
--- @module 'plugin_name._cli.cli_subcommand'
---

local M = {}

--- Check if `full` contains `prefix` + whitespace.
---
--- @param full string Some full text like `"PluginName blah"`.
--- @param prefix string The expected starting text. e.g. `"PluginName"`.
--- @return boolean # If a subcommand syntax was found, return true.
---
local function _is_subcommand(full, prefix)
    local expression = "^" .. prefix .. "%s+%w*$"

    return full:match(expression)
end

--- Get the auto-complete, if any, for a subcommand.
---
--- @param text string Some full text like `"PluginName blah"`.
--- @param prefix string The expected starting text. e.g. `"PluginName"`.
--- @param subcommands PluginNameSubcommands All allowed commands.
---
local function _get_subcommand_completion(text, prefix, subcommands)
    local expression = "^" .. prefix .. "*%s(%S+)%s(.*)$"
    local subcommand, arguments = text:match(expression)

    if not subcommand or not arguments then
        return nil
    end

    if subcommands[subcommand] and subcommands[subcommand].complete then
        return subcommands[subcommand].complete(arguments)
    end

    return nil
end

--- Create a function that implements "Vim COMMAND mode auto-complete".
---
--- Basically it's a function that returns a function that makes `:PluginName
--- hello` auto-complete to makes `:PluginName hello-world`.
---
--- @param prefix string The command to exclude from auto-complete. e.g. `"PluginName"`.
--- @param subcommands PluginNameSubcommands All allowed commands.
--- @return function # The generated auto-complete function.
---
function M.make_command_completer(prefix, subcommands)
    local function runner(args, text, _)
        local completion = _get_subcommand_completion(text, prefix, subcommands)

        if completion then
            return completion
        end

        if _is_subcommand(text, prefix) then
            local keys = vim.tbl_keys(subcommands)
            return vim.iter(keys)
                :filter(function(key)
                    return key:find(args) ~= nil
                end)
                :totable()
        end

        return nil
    end

    return runner
end

-- TODO: Finish this
function M.get_complete_options(data, positional_choices, named_choices)
    -- print('DEBUGPRINT[3]: cli_subcommand.lua:63: data=' .. vim.inspect(data))
    -- print('DEBUGPRINT[4]: cli_subcommand.lua:63: positional_choices=' .. vim.inspect(positional_choices))
    -- print('DEBUGPRINT[5]: cli_subcommand.lua:63: named_choices=' .. vim.inspect(named_choices))
    return { "aa", "bbb", "ccccc" }
end

--- Wrap the `plugin_name` CLI / API in a way Neovim understands.
---
--- Since `:PluginName` supports multiple sub-commands like `:PluginName
--- hello-world` and `:PluginName goodnight-moon`, something has to make sure
--- that the right Lua function gets called depending on what the user asks for.
---
--- This function handles that process, which we call "triage".
---
--- @param subcommands PluginNameSubcommands
---     All registered commands for `plugin_name` which we will let users run.
---     If the user gives an incorrect subcommand name, an error is displayed instead.
---
function M.make_triager(subcommands)
    --- Check for a subcommand and, if found, call its `run` caller field.
    ---
    --- @source `:h lua-guide-commands-create`
    ---
    --- @param opts table
    ---
    local function runner(opts)
        local fargs = opts.fargs
        local subcommand_key = fargs[1]
        local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
        local subcommand = subcommands[subcommand_key]

        if not subcommand then
            vim.notify("PluginName: Unknown command: " .. subcommand_key, vim.log.levels.ERROR)

            return
        end

        subcommand.run(args, opts)
    end

    return runner
end

return M
