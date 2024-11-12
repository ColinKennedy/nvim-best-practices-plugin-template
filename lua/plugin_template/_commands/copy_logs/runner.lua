--- The main file that implements `copy-logs` outside of COMMAND mode.
---
---@module 'plugin_template._commands.copy_logs.runner'
---

local vlog = require("plugin_template._vendors.vlog")

local M = {}

--- Modify the user's system clipboard with `result`.
---
---@param result plugin_template.ReadFileResult The file path + its contents that we read.
---
local function _callback(result)
    vim.fn.setreg("+", result.data)

    vim.notify(string.format('Log file "%s" was copied to the clipboard.', result.path), vim.log.levels.INFO)
end

---@class plugin_template.ReadFileResult
---    A file path + its contents.
---@field data string
---    The blob of text that was read from `path`.
---@field path string
---    An absolute path to a file on-disk.

--- Read the contents of `path` and pass its contents to `callback`.
---
---@param path string An absolute path to a file on-disk.
---@param callback fun(result: plugin_template.ReadFileResult): nil Call this once `path` is read.
---
function M._read_file(path, callback)
    -- NOTE: mode 428 == rw-rw-rw-
    vim.uv.fs_open(path, "r", 438, function(error_open, handler)
        if error_open then
            error(error_open)
        end
        if not handler then
            error(string.format('Path "%s" could not be opened.', path))
        end

        vim.uv.fs_fstat(handler, function(error_stat, stat)
            if error_stat then
                error(error_stat)
            end
            if not stat then
                error(string.format('Path "%s" could not be stat-ed.', path))
            end

            vim.uv.fs_read(handler, stat.size, 0, function(error_read, data)
                if error_read then
                    error(error_read)
                end
                if not data then
                    error(string.format('Path "%s" could no be read for data.', path))
                end

                vim.uv.fs_close(handler, function(error_close)
                    assert(not error_close, error_close)

                    return callback({ data = data, path = path })
                end)
            end)
        end)
    end)
end

--- Copy the log data from the given `path` to the user's clipboard.
---
---@param path string?
---    A path on-disk to look for logs. If none is given, the default fallback
---    location is used instead.
---
function M.run(path)
    path = path or vlog:get_log_path()

    if not path or vim.fn.filereadable(path) ~= 1 then
        vim.notify(string.format('No "%s" path. Cannot copy the logs.', path), vim.log.levels.ERROR)

        return
    end

    local success, _ = pcall(M._read_file, path, vim.schedule_wrap(_callback))

    if not success then
        vim.notify(string.format('Failed to read "%s" path. Cannot copy the logs.', path), vim.log.levels.ERROR)
    end
end

return M
