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
        description="Print to the user X number of times (default=1).",
    })
end

local function _add_style_argument(parser)
    parser:add_argument({
        names = { "--style", "-s" },
        choices = {
            constant.Keyword.style.lowercase,
            constant.Keyword.style.uppercase,
        },
        description="lowercase modifies all capital letters. uppercase modifies all non-capital letter.",
    })
end

function M.make_parser()
    local parser = argparse2.ArgumentParser.new({"hello-world", description="Print hello to the user."})
    local subparsers = parser:add_subparsers({destination="commands", description="All allowed commands."})
    subparsers.required = true

    local phrase = subparsers:add_parser({"phrase", description="Print everything that the user types."})
    _add_repeat_argument(phrase)
    _add_style_argument(phrase)

    local word = subparsers:add_parser({"phrase", description="Print only the first word that the user types."})
    _add_repeat_argument(word)
    _add_style_argument(word)

    phrase:set_execute(
        function(data)
            local command = require("plugin_template._commands.hello_world.say.command")

            command.run_phrase(data.namespace)
        end
    )

    word:set_execute(
        function(data)
            local command = require("plugin_template._commands.hello_world.say.command")

            command.run_word(data.namespace)
        end
    )
end

return M
