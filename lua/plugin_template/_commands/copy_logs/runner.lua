--- The main file that implements `copy-logs` outside of COMMAND mode.
---
--- @module 'plugin_template._commands.copy_logs.runner'
---

local state = require("plugin_template._core.state")
local vlog = require("plugin_template._vendors.vlog")

local M = {}

--- Copy the log data from the given `path` to the user's clipboard.
---
--- @param path string?
---     A path on-disk to look for logs. If none is given, the default fallback
---     location is used instead.
---
function M.run(path)
    state.PREVIOUS_COMMAND = "copy_logs"

    path = path or vlog:get_log_path()

    if not path or vim.fn.filereadable(path) ~= 1 then
        vim.notify(
            string.format('No "%s" path. Cannot copy the logs.', path),
            vim.log.levels.ERROR
        )

        return
    end

    local file = io.open(path, "r")

    if not file then
      vim.notify(
          string.format('Failed to read "%s" path. Cannot copy the logs.', path),
          vim.log.levels.ERROR
      )

      return
    end

    local contents = file:read("*a")

    file:close()

    vim.fn.setreg("+", contents)

    vim.notify(
        string.format('Log file "%s" was copied to the clipboard.', path),
        vim.log.levels.INFO
    )
end

return M
