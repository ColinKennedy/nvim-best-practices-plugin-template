-- TODO: Docstring

local argparse2 = require("plugin_template._cli.argparse2")

local M = {}

function M.make_parser()
    local parser = argparse2.ArgumentParser.new({"arbitrary-thing", description="Prepare to sleep or sleep."})

    parser:add_argument({"-a"})
    parser:add_argument({"-b"})
    parser:add_argument({"-c"})
    parser:add_argument({"-v", count="*", destination="verbose"})
    parser:add_argument({"-f", count="*"})

    return parser
end

return M
