--- Connect Neovim's COMMAND mode to our Lua functions.
---
--- @module 'plugin_template._cli.cli_subcommand'
---

local M = {}

-- TODO: Fix documentation here later

--- @class plugin_template.CompleteData
---     The data that gets passed when `plugin_template.Subcommand.complete` is called.
--- @field parsed_arguments argparse.ArgparseResults
---     All information that was found from parsing some user's input.

--- @class plugin_template.RunData
---     The data that gets passed when `plugin_template.Subcommand.run` is called.
--- @field parsed_arguments argparse.ArgparseResults
---     All information that was found from parsing some user's input.

--- @class plugin_template.Subcommand
---     A subparser's definition. At minimum you need to define `parser` or
---     `run` or code will error when you try to run commands. If you define
---     `parser`, you don't need to define `complete` or `run` (`parser` is the
---     preferred way to make parsers).
--- @field complete (fun(data: plugin_template.CompleteData): string[])?
---     Command completions callback, the `data` are  the lead of the subcommand's arguments
--- @field parser (fun(): argparse2.ParameterParser)?
---     The primary parser used for subcommands. It handles auto-complete,
---     expression-evaluation, and running a user's code.
--- @field run (fun(data: plugin_template.SubcommandRun): nil)?
---     The function to run when the subcommand is called.

--- @class plugin_template.SubcommandRun
---     TODO Finish this later

--- @alias plugin_template.Subcommands table<string, plugin_template.Subcommand | fun(): argparse2.ParameterParser>

--- Check if `full` contains `prefix` + whitespace.
---
--- @param full string Some full text like `"PluginTemplate blah"`.
--- @param prefix string The expected starting text. e.g. `"PluginTemplate"`.
--- @return boolean # If a subcommand syntax was found, return true.
---
local function _is_subcommand(full, prefix)
    local expression = "^" .. prefix .. "%s+.*$"

    return full:match(expression) ~= nil
end

--- Get the auto-complete, if any, for a subcommand.
---
--- @param text string Some full text like `"PluginTemplate blah"`.
--- @param prefix string The expected starting text. e.g. `"PluginTemplate"`.
--- @param subcommands plugin_template.Subcommands All allowed commands.
---
local function _get_subcommand_completion(text, prefix, subcommands)
    local argparse = require("plugin_template._cli.argparse")

    local expression = "^" .. prefix .. "*%s(%S+)%s(.*)$"
    local subcommand_key, arguments = text:match(expression)

    if not subcommand_key or not arguments then
        return nil
    end

    if not subcommands[subcommand_key] then
        vim.notify(
            string.format(
                'PluginTemplate: Unknown command "%s". Please check your spelling and try again.',
                subcommand_key
            ),
            vim.log.levels.ERROR
        )

        return nil
    end

    local subcommand = subcommands[subcommand_key]

    if type(subcommand) == "function" then
        local parser = subcommand()

        if not parser then
            vim.notify(
                string.format('Subcommand "%s" does not define a parser. Please fix!', subcommand_key),
                vim.log.levels.ERROR
            )

            return nil
        end

        local column = vim.fn.getcmdpos()

        return parser:get_completion(arguments, column)
    end

    if subcommand.parser then
        local parser = subcommand.parser()
        local column = vim.fn.getcmdpos()

        return parser:get_completion(arguments, column)
    end

    if subcommand.complete then
        -- TODO: Make sure this works still
        local result = subcommand.complete({ parsed_arguments = argparse.parse_arguments(arguments) })

        if result == nil or vim.islist(result) then
            if arguments == "" then
                arguments = "<No arguments>"
            end

            vim.notify(
                string.format(
                    'plugin-template: Subcommand / Arguments "%s / %s" must be a string[]. Got "%s".',
                    subcommand,
                    arguments,
                    vim.inspect(result)
                )
            )

            return result
        end

        return
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

local function _run_subcommand(parser, text)
    local argparse = require("plugin_template._cli.argparse")

    local arguments = argparse.parse_arguments(text)
    local namespace = parser:parse_arguments(arguments)

    if namespace.execute then
        -- TODO: Make sure this has the right type-hint
        namespace.execute({ input = arguments, namespace = namespace })

        return
    end

    vim.notify(
        string.format(
            'PluginTemplate: Command "%s" parsed "%s" text into "%s" namespace but no `execute` '
                .. "function was defined. "
                .. 'Call parser:set_execute(function() print("Your function here") end)',
            parser.name or parser.help or "<No name or help for this parser was provided>",
            text,
            vim.inspect(namespace)
        ),
        vim.log.levels.ERROR
    )
end

local function _strip_prefix(prefix, text)
    return (text:gsub("^" .. _escape(prefix) .. "%s*", ""))
end

--- Create a function that implements "Vim COMMAND mode auto-complete".
---
--- Basically it's a function that returns a function that makes `:PluginTemplate
--- hello` auto-complete to makes `:PluginTemplate hello-world`.
---
--- @param prefix string The command to exclude from auto-complete. e.g. `"PluginTemplate"`.
--- @param subcommands plugin_template.Subcommands All allowed commands.
--- @return function # The generated auto-complete function.
---
function M.make_command_completer(prefix, subcommands)
    local function runner(args, text, _)
        local configuration = require("plugin_template._core.configuration")
        configuration.initialize_data_if_needed()
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

-- TODO: Fix this doc + the others
--- If anything in `subcommands` is missing data, define default value(s) for it.
---
--- @param subcommands plugin_template.Subcommands
---     All registered commands for `plugin_template` to possibly modify.
---
function M.initialize_missing_values(subcommands)
    for _, subcommand in pairs(subcommands) do
        if type(subcommand) == "table" and not subcommand.complete then
            subcommand.complete = function()
                return {}
            end
        end
    end
end

--- Wrap the `plugin_template` CLI / API in a way Neovim understands.
---
--- Since `:PluginTemplate` supports multiple sub-commands like `:PluginTemplate
--- hello-world` and `:PluginTemplate goodnight-moon`, something has to make sure
--- that the right Lua function gets called depending on what the user asks for.
---
--- This function handles that process, which we call "triage".
---
--- @param subcommands plugin_template.Subcommands
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
        local configuration = require("plugin_template._core.configuration")
        local argparse = require("plugin_template._cli.argparse")
        configuration.initialize_data_if_needed()

        local subcommand_key = opts.fargs[1]
        local subcommand = subcommands[subcommand_key]

        if not subcommand then
            vim.notify("PluginTemplate: Unknown command: " .. subcommand_key, vim.log.levels.ERROR)

            return
        end

        local stripped_text = _strip_prefix(subcommand_key, opts.args)

        if type(subcommand) == "function" then
            local parser = subcommand()

            if not parser then
                vim.notify(
                    string.format('Subcommand "%s" does not define a parser. Please fix!', subcommand_key),
                    vim.log.levels.ERROR
                )

                return
            end

            _run_subcommand(parser, stripped_text)

            return
        end

        if subcommand.parser then
            local parser = subcommand.parser()
            _run_subcommand(parser, stripped_text)

            return
        end

        if subcommand.run then
            -- TODO: Add a unittest. Make sure this still works
            subcommand.run(vim.tbl_deep_extend("force", opts, {
                parsed_arguments = argparse.parse_arguments(stripped_text),
            }))
        end

        vim.notify(string.format('Subcommand "%s" must define `parser` or `run`.', vim.log.levels.ERROR))
    end

    return runner
end

return M
