--- Connect Neovim's COMMAND mode to our Lua functions.
---
---@module 'plugin_template._cli.cli_subcommand'
---

local M = {}

---@class argparse.SubcommandRunnerOptions
---    User input to send to the legacy argparse API.
---@field args string
---    The full user input text, unparsed. e.g. `"some_subcommand arg1 --flag --foo=bar"`.
---@field fargs string[]
---    The parsed user input text. e.g. `{"some_subcommand", "arg1", "--flag" "--foo=bar"}`.

---@class plugin_template.NamespaceExecuteArguments
---    The expected data that's passed to any `set_execute` call in plugin-template.
---@field input argparse.Results
---    The user's raw input, split into tokens.
---@field namespace cmdparse.Namespace
---    The collected results from comparing `input` to our cmdparse tree.

---@class plugin_template.CompleteData
---    The data that gets passed when `plugin_template.Subcommand.complete` is called.
---@field input argparse.Results
---    All information that was found from parsing some user's input.

---@class plugin_template.RunData
---    The data that gets passed when `plugin_template.Subcommand.run` is called.
---@field input argparse.Results
---    All information that was found from parsing some user's input.

---@class plugin_template.Subcommand
---    A subparser's definition. At minimum you need to define `parser` or
---    `run` or code will error when you try to run commands. If you define
---    `parser`, you don't need to define `complete` or `run` (`parser` is the
---    preferred way to make parsers).
---@field complete (fun(data: plugin_template.CompleteData): string[])?
---    Command completions callback, the `data` are  the lead of the subcommand's arguments
---@field parser (fun(): cmdparse.ParameterParser)?
---    The primary parser used for subcommands. It handles auto-complete,
---    expression-evaluation, and running a user's code.
---@field run (fun(data: plugin_template.SubcommandRun): nil)?
---    The function to run when the subcommand is called.

---@class plugin_template.SubcommandRun
---    The data that gets passed to the `run` function. Most of the time,
---    a user never needs or touches this data. It's only for people who need
---    absolute control over the CLI or some unsupported behavior.
---@field input argparse.Results
---    The parsed arguments (that the user is now trying to execute some function with).

---@alias plugin_template.ParserCreator fun(): cmdparse.ParameterParser

---@alias plugin_template.Subcommands table<string, plugin_template.Subcommand | fun(): cmdparse.ParameterParser>

--- Check if `full` contains `prefix` + whitespace.
---
---@param full string Some full text like `"PluginTemplate blah"`.
---@param prefix string The expected starting text. e.g. `"PluginTemplate"`.
---@return boolean # If a subcommand syntax was found, return true.
---
local function _is_subcommand(full, prefix)
    local expression = "^" .. prefix .. "%s+.*$"

    return full:match(expression) ~= nil
end

--- Get the auto-complete, if any, for a subcommand.
---
---@param text string Some full text like `"PluginTemplate blah"`.
---@param prefix string The expected starting text. e.g. `"PluginTemplate"`.
---@param subcommands plugin_template.Subcommands All allowed commands.
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

    ---@cast subcommand plugin_template.Subcommand

    if subcommand.parser then
        local parser = subcommand.parser()
        local column = vim.fn.getcmdpos()

        return parser:get_completion(arguments, column)
    end

    if subcommand.complete then
        local result = subcommand.complete({ input = argparse.parse_arguments(arguments) })

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

        return nil
    end

    return nil
end

--- Run `parser` and pass it the user's raw input `text`.
---
---@param parser cmdparse.ParameterParser The decision tree that parses and runs `text`.
---@param text string The (unparsed) text that user provides from COMMAND mode.
---
local function _run_subcommand(parser, text)
    local argparse = require("plugin_template._cli.argparse")

    local arguments = argparse.parse_arguments(text)
    local namespace = parser:parse_arguments(arguments)
    ---@type fun(data: plugin_template.NamespaceExecuteArguments): nil
    local execute = namespace.execute

    if execute then
        execute({ input = arguments, namespace = namespace })

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

--- Remove `prefix` from `text` if needed.
---
---@param prefix string A character / phrase to remove from `text`.
---@param text string The text that might start with `prefix`.
---@return string # Basically `text.lstrip(prefix)`.
---
local function _strip_prefix(prefix, text)
    return (text:gsub("^" .. vim.pesc(prefix) .. "%s*", ""))
end

--- If anything in `subcommands` is missing data, define default value(s) for it.
---
---@param subcommands plugin_template.Subcommands
---    All registered commands for `plugin_template` to possibly modify.
---
function M.initialize_missing_values(subcommands)
    if type(subcommands) == "table" then
        for _, subcommand in pairs(subcommands) do
            if type(subcommand) == "table" and not subcommand.complete then
                subcommand.complete = function()
                    return {}
                end
            end
        end
    end
end

--- Create a deferred function that can parse and execute a user's arguments.
---
---@param parser_creator plugin_template.ParserCreator
---    A function that creates the decision tree that parses text.
---@return fun(opts: table): nil
---    A function that will parse the user's arguments.
---
function M.make_parser_triager(parser_creator)
    local function runner(opts)
        local argparse = require("plugin_template._cli.argparse")

        local text = opts.name .. " " .. opts.args
        local arguments = argparse.parse_arguments(text)
        local parser = parser_creator()
        local success
        ---@type table<string, any> | string
        local result
        success, result = pcall(function()
            return parser:parse_arguments(arguments)
        end)

        if not success then
            ---@cast result string The error message.
            vim.notify(result, vim.log.levels.ERROR)

            return
        end

        ---@type fun(data: plugin_template.NamespaceExecuteArguments): nil
        local execute = result.execute

        if execute then
            execute({ input = arguments, namespace = result })

            return
        end

        vim.notify(parser:get_concise_help(text), vim.log.levels.ERROR)
    end

    return runner
end

--- Make a function that can auto-complete based on the parser of `parser_creator`.
---
---@param parser_creator plugin_template.ParserCreator
---    A function that creates the decision tree that parses text.
---@return fun(_: any, all_text: string, _: any): string[]?
---    A deferred function that creates the COMMAND mode parser, runs it, and
---    gets all auto-complete values back if any were found.
---
function M.make_parser_completer(parser_creator)
    local function runner(_, all_text, _)
        local configuration = require("plugin_template._core.configuration")
        configuration.initialize_data_if_needed()

        local parser = parser_creator()
        local column = vim.fn.getcmdpos()

        return parser:get_completion(all_text, column)
    end

    return runner
end

--- Use `subcommands` to make a COMMAND mode auto-completer.
---
---@param prefix string The command to exclude from auto-complete. e.g. `"PluginTemplate"`.
---@param subcommands plugin_template.Subcommands All allowed commands.
---@return fun(latest_text: string, all_text: string): string[]? # The generated auto-complete function.
---
function M.make_subcommand_completer(prefix, subcommands)
    local function runner(latest_text, all_text, _)
        local configuration = require("plugin_template._core.configuration")
        configuration.initialize_data_if_needed()

        local completion = _get_subcommand_completion(all_text, prefix, subcommands)

        if completion then
            return completion
        end

        if _is_subcommand(all_text, prefix) then
            local escaped_latest_text = vim.pesc(latest_text)
            local keys = vim.tbl_keys(subcommands)
            local output = {}

            for _, key in ipairs(keys) do
                if key:find(escaped_latest_text) ~= nil then
                    table.insert(output, key)
                end
            end

            return output
        end

        return nil
    end

    return runner
end

--- Create a deferred function that creates separate parsers for each subcommand.
---
---@param subcommands plugin_template.Subcommands
---    Each subcommand to register.
---@return fun(opts: argparse.SubcommandRunnerOptions): nil
---    A function that will parse the user's arguments.
---
function M.make_subcommand_triager(subcommands)
    --- Check for a subcommand and, if found, call its `run` caller field.
    ---
    ---
    ---@param opts argparse.SubcommandRunnerOptions The parsed user inputs.
    ---
    local function _runner(opts)
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
            subcommand.run(vim.tbl_deep_extend("keep", { input = argparse.parse_arguments(stripped_text) }, opts))

            return
        end

        vim.notify(string.format('Subcommand "%s" must define `parser` or `run`.', vim.log.levels.ERROR))
    end

    --- Check for a subcommand and, if found, call its `run` caller field.
    ---
    ---
    ---@param opts argparse.SubcommandRunnerOptions The parsed user options.
    ---
    local function runner(opts)
        local configuration = require("plugin_template._core.configuration")
        configuration.initialize_data_if_needed()

        local help_message = require("plugin_template._cli.cmdparse.help_message")

        local success, result = pcall(function()
            _runner(opts)
        end)

        if not success then
            ---@cast result string

            if help_message.is_help_message(result) then
                help_message.show_help(result)

                return
            end

            error(result)
        end
    end

    return runner
end

return M
