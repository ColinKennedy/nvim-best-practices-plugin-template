--- The main parser for the `:PluginTemplate hello-world` command.
---
---@module 'plugin_template._commands.hello_world.parser'
---

local cmdparse = require("plugin_template._cli.cmdparse")
local constant = require("plugin_template._commands.hello_world.say.constant")

local M = {}

--- Add the `--repeat` parameter onto `parser`.
---
---@param parser cmdparse.ParameterParser The parent parser to add the parameter onto.
---
local function _add_repeat_parameter(parser)
    parser:add_parameter({
        names = { "--repeat", "-r" },
        choices = function(data)
            --- @cast data cmdparse.ChoiceData?

            local output = {}

            if not data or not data.current_value or data.current_value == "" then
                for index = 1, 5 do
                    table.insert(output, tostring(index))
                end

                return output
            end

            local value = tonumber(data.current_value)

            if not value then
                return {}
            end

            table.insert(output, tostring(value))

            for index = 1, 4 do
                table.insert(output, tostring(value + index))
            end

            return output
        end,
        default = 1,
        help = "Print to the user X number of times (default=1).",
    })
end

--- Add the `--style` parameter onto `parser`.
---
---@param parser cmdparse.ParameterParser The parent parser to add the parameter onto.
---
local function _add_style_parameter(parser)
    parser:add_parameter({
        names = { "--style", "-s" },
        choices = {
            constant.Keyword.style.lowercase,
            constant.Keyword.style.uppercase,
        },
        help = "lowercase makes WORD into word. uppercase does the reverse.",
    })
end

---@return cmdparse.ParameterParser # The main parser for the `:PluginTemplate hello-world` command.
function M.make_parser()
    local parser = cmdparse.ParameterParser.new({ "hello-world", help = "Print hello to the user." })
    local top_subparsers =
        parser:add_subparsers({ destination = "commands", help = "All hello-world commands.", required = true })
    --- @cast top_subparsers cmdparse.Subparsers

    local say = top_subparsers:add_parser({ "say", help = "Print something to the user." })
    local subparsers =
        say:add_subparsers({ destination = "say_commands", help = "All say-related commands.", required = true })

    local phrase = subparsers:add_parser({ "phrase", help = "Print everything that the user types." })
    phrase:add_parameter({ "phrases", count = "*", action = "append", help = "All of the text to print." })
    _add_repeat_parameter(phrase)
    _add_style_parameter(phrase)

    local word = subparsers:add_parser({ "word", help = "Print only the first word that the user types." })
    word:add_parameter({ "word", help = "The word to print." })
    _add_repeat_parameter(word)
    _add_style_parameter(word)

    phrase:set_execute(function(data)
        ---@cast data plugin_template.NamespaceExecuteArguments
        local runner = require("plugin_template._commands.hello_world.say.runner")

        local phrases = data.namespace.phrases

        if not phrases then
            phrases = {}
        end

        runner.run_say_phrase(phrases, data.namespace["repeat"], data.namespace.style)
    end)

    word:set_execute(function(data)
        ---@cast data plugin_template.NamespaceExecuteArguments
        local runner = require("plugin_template._commands.hello_world.say.runner")

        runner.run_say_word(data.namespace.word or "", data.namespace["repeat"], data.namespace.style)
    end)

    return parser
end

return M
