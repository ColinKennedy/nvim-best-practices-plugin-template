local copy_logs_runner = require("plugin_template._commands.copy_logs.runner")

local M = {}

-- TODO: Docstrings
function M.run(path)
    copy_logs_runner.run(path)
end

return M
