-- TODO: Replace with "hello-world" file name

-- TODO: Docstrings

local configuration_ = require("plugin_name._core.configuration")

local M = {}

function M.run_hello_world(data, configuration)
    data = configuration_.resolve_data(configuration) or configuration_.DATA

    print(vim.inspect(data))
end

return M
