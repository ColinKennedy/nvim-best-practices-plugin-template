--- Parse `"copy-logs"` from COMMAND mode and run it.
---
--- @module 'plugin_template._commands.copy_logs.command'
---

local copy_logs_runner = require("plugin_template._commands.copy_logs.runner")

local M = {}

--- Parse `"copy-logs"` from COMMAND mode and run it.
---
--- @param path string?
---     A path on-disk to look for logs. If none is given, the default fallback
---     location is used instead.
---
function M.run(path)
    copy_logs_runner.run(path)
end

return M
