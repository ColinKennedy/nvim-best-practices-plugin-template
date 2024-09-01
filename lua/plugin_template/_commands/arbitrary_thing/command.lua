--- Parse `"arbitrary-thing"` from the COMMAND mode and run it.
---
--- @module 'plugin_template._commands.arbitrary_thing.command'
---

local arbitrary_thing_runner = require("plugin_template._commands.arbitrary_thing.runner")
local argparse = require("plugin_template._cli.argparse")
local vlog = require("plugin_template._vendors.vlog")

local M = {}

--- Find the label name of `option`.
---
--- - --foo = foo
--- - --foo=bar = foo
--- - -f = f
--- - foo = foo
---
--- @param option ArgparseArgument Some argument / option to query.
--- @return string # The found name.
---
local function _get_argument_name(option)
    if option.argument_type == argparse.ArgumentType.position then
        --- @cast option PositionOption
        return option.value
    end

    if option.argument_type == argparse.ArgumentType.flag or option.argument_type == argparse.ArgumentType.named then
        return option.name
    end

    vlog.fmt_error('Unabled to find a label for "%s" option.', option)

    return ""
end

--- Parse `"arbitrary-thing"` from the COMMAND mode and run it.
---
--- @param data ArgparseResults All found user data.
---
function M.run(data)
    local names = {}

    for _, argument in ipairs(data.arguments) do
        table.insert(names, _get_argument_name(argument))
    end

    arbitrary_thing_runner.run(names)
end

return M
