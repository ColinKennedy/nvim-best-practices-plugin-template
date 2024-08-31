--- Parse + get auto-complete text from the user's `:PluginTemplate hello-world` input.
---
--- @module 'plugin_template._commands.hello_world.complete'
---

local argparse = require("plugin_template._cli.argparse")
local completion = require("plugin_template._cli.completion")
local constant = require("plugin_template._commands.hello_world.say.constant")

local M = {}

local _TAIL_ARGUMENTS = {
    {
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
        name = "repeat",
        argument_type = argparse.ArgumentType.named,
    },
    {
        argument_type = argparse.ArgumentType.named,
        name = "style",
        choices = {
            constant.Keyword.style.lowercase,
            constant.Keyword.style.uppercase,
        },
    },
}

local _TREE = {
    say = {
        [constant.Subcommand.phrase] = _TAIL_ARGUMENTS,
        [constant.Subcommand.word] = _TAIL_ARGUMENTS,
    },
}

--- Parse for positional arguments, named arguments, and flag arguments.
---
--- @param data string
---     Some command to parse. e.g. `bar -f --buzz --some="thing else"`.
--- @return string[]
---     All of the auto-completion options that were found, if any.
---
function M.complete(data)
    local arguments = argparse.parse_arguments(data)

    return completion.get_options(_TREE, arguments, vim.fn.getcmdpos())
end

return M
