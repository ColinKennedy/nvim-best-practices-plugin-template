--- Connect Neovim's COMMAND mode to our Lua functions.
---
--- @module 'plugin_template._cli.cli_subcommand'
---

local M = {}

--- Check if `full` contains `prefix` + whitespace.
---
--- @param full string Some full text like `"PluginTemplate blah"`.
--- @param prefix string The expected starting text. e.g. `"PluginTemplate"`.
--- @return boolean # If a subcommand syntax was found, return true.
---
local function _is_subcommand(full, prefix)
    local expression = "^" .. prefix .. "%s+%w*$"

    return full:match(expression)
end

--- Get the auto-complete, if any, for a subcommand.
---
--- @param text string Some full text like `"PluginTemplate blah"`.
--- @param prefix string The expected starting text. e.g. `"PluginTemplate"`.
--- @param subcommands PluginTemplateSubcommands All allowed commands.
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

--- Change `text` to something that will work with Lua regex.
---
--- @param text string Some raw text. e.g. `"foo-bar"`.
--- @return string # Escaped text, e.g. `"foo%-bar"`.
---
local function _escape(text)
    local escaped = text:gsub("%-", "%%-")

    return escaped
end

--- Create a function that implements "Vim COMMAND mode auto-complete".
---
--- Basically it's a function that returns a function that makes `:PluginTemplate
--- hello` auto-complete to makes `:PluginTemplate hello-world`.
---
--- @param prefix string The command to exclude from auto-complete. e.g. `"PluginTemplate"`.
--- @param subcommands PluginTemplateSubcommands All allowed commands.
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
            local output = {}

            for _, key in ipairs(keys) do
                if key:find(_escape(args)) ~= nil then
                    table.insert(output, key)
                end
            end

            return output
        end

        return nil
    end

    return runner
end

-- TODO: Finish this
function M.get_complete_options(data, positional_choices, named_choices)
    return { "aa", "bbb", "ccccc" }
end

--- Wrap the `plugin_template` CLI / API in a way Neovim understands.
---
--- Since `:PluginTemplate` supports multiple sub-commands like `:PluginTemplate
--- hello-world` and `:PluginTemplate goodnight-moon`, something has to make sure
--- that the right Lua function gets called depending on what the user asks for.
---
--- This function handles that process, which we call "triage".
---
--- @param subcommands PluginTemplateSubcommands
---     All registered commands for `plugin_template` which we will let users run.
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
        local argparse = require("plugin_template._cli.argparse")

        local subcommand_key = opts.fargs[1]
        local subcommand = subcommands[subcommand_key]

        if not subcommand then
            vim.notify(
                "PluginTemplate: Unknown command: " .. subcommand_key,
                vim.log.levels.ERROR
            )

            return
        end

        local results = argparse.parse_arguments(opts.args)
        subcommand.run(results)
    end

    return runner
end

return M
