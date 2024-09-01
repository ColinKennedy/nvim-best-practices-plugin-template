--- Parse + get auto-complete text from the user's `:PluginTemplate arbitrary-thing` input.
---
--- @module 'plugin_template._commands.arbitrary_thing.complete'
---

local argparse = require("plugin_template._cli.argparse")
local completion = require("plugin_template._cli.completion")

local _TREE = {
    {
        {
            argument_type = argparse.ArgumentType.flag,
            count = "*",
            name = "f",
        },

        {
            argument_type = argparse.ArgumentType.flag,
            name = "a",
        },
        {
            argument_type = argparse.ArgumentType.flag,
            name = "b",
        },
        {
            argument_type = argparse.ArgumentType.flag,
            name = "c",
        },

        {
            argument_type = argparse.ArgumentType.flag,
            count = "*",
            name = "v",
        },
    },
}

local M = {}

--- Parse for positional arguments, named arguments, and flag arguments.
---
--- @param data string
---     Some command to parse. e.g. `-vvv -abc -f`.
--- @return string[]
---     All of the auto-completion options that were found, if any.
---
function M.complete(data)
    local arguments = argparse.parse_arguments(data)

    return completion.get_options(_TREE, arguments, vim.fn.getcmdpos())
end

return M
