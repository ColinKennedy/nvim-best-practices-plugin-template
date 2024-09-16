-- TODO: Docstring

local argparse2 = require("plugin_template._cli.argparse2")
local constant = require("plugin_template._commands.hello_world.say.constant")

local M = {}

local function _add_repeat_argument(parser)
    parser:add_argument({
        names = { "--repeat", "-r" },
        choices = function(data)
            local value = data.text

            if value == "" then
                value = 0
            else
                value = tonumber(value)

                if type(value) ~= "number" then
                    return {}
                end
            end

            --- @cast value number

            local output = {}

            for index = 1, 5 do
                table.insert(output, tostring(value + index))
            end

            return output
        end,
        default = 1,
        help = "Print to the user X number of times (default=1).",
    })
end

local function _add_style_argument(parser)
    parser:add_argument({
        names = { "--style", "-s" },
        choices = {
            constant.Keyword.style.lowercase,
            constant.Keyword.style.uppercase,
        },
        help = "lowercase modifies all capital letters. uppercase modifies all non-capital letter.",
    })
end

function M.make_parser()
    local parser = argparse2.ArgumentParser.new({ "hello-world", help = "Print hello to the user." })
    local top_subparsers = parser:add_subparsers({ destination = "commands", help = "All allowed commands." })
    top_subparsers.required = true

    local say = top_subparsers:add_parser({ "say", help = "Print something to the user." })
    local subparsers = say:add_subparsers({ destination = "say_commands", help = "All say-related commands." })
    subparsers.required = true

    local phrase = subparsers:add_parser({ "phrase", help = "Print everything that the user types." })
    phrase:add_argument({ "phrases", count = "*", action = "append", help = "All of the text to print." })
    _add_repeat_argument(phrase)
    _add_style_argument(phrase)

    local word = subparsers:add_parser({ "word", help = "Print only the first word that the user types." })
    word:add_argument({ "word", help = "The word to print." })
    _add_repeat_argument(word)
    _add_style_argument(word)

    phrase:set_execute(function(data)
        local runner = require("plugin_template._commands.hello_world.say.runner")

        local phrases = data.namespace.phrases

        if not phrases then
            phrases = {}
        end

        runner.run_say_phrase(phrases, data.namespace["repeat"], data.namespace.style)
    end)

    word:set_execute(function(data)
        local runner = require("plugin_template._commands.hello_world.say.runner")

        runner.run_say_word(data.namespace.word or "", data.namespace["repeat"], data.namespace.style)
    end)

    return parser
end

return M
