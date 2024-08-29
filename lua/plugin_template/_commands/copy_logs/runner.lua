--- The main file that implements `copy-logs` outside of COMMAND mode.
---
--- @module 'plugin_template._commands.copy_logs.runner'
---

local state = require("plugin_template._core.state")
local vlog = require("plugin_template._vendors.vlog")

local M = {}

--- @class ReadFileResult
---     A file path + its contents.
--- @field data string
---     The blob of text that was read from `path`.
--- @field path string
---     An absolute path to a file on-disk.

--- Read the contents of `path` and pass its contents to `callback`.
---
--- @param path string An absolute path to a file on-disk.
--- @param callback fun(result: ReadFileResult): nil Call this once `path` is read.
---
local function _read_file(path, callback)
    vim.uv.fs_open(path, "r", 438, function(error, handler)  -- NOTE: mode 428 == rw-rw-rw-
        --- @cast error string
        assert(not error, error)

        vim.uv.fs_fstat(handler, function(error, stat)
            assert(not error, error)

            vim.uv.fs_read(handler, stat.size, 0, function(error, data)
                assert(not error, error)

                vim.uv.fs_close(handler, function(error)
                    assert(not error, error)

                    return callback({ data = data, path = path })
                end)
            end)
        end)
    end)
end

--- Copy the log data from the given `path` to the user's clipboard.
---
--- @param path string?
---     A path on-disk to look for logs. If none is given, the default fallback
---     location is used instead.
---
function M.run(path)

    --- Modify the user's system clipboard with `result`.
    ---
    --- @param result ReadFileResult The file path + its contents that we read.
    ---
    local function _callback(result)
        vim.fn.setreg("+", result.data)

        vim.notify(string.format('Log file "%s" was copied to the clipboard.', result.path), vim.log.levels.INFO)
    end

    state.PREVIOUS_COMMAND = "copy_logs"

    path = path or vlog:get_log_path()

    if not path or vim.fn.filereadable(path) ~= 1 then
        vim.notify(string.format('No "%s" path. Cannot copy the logs.', path), vim.log.levels.ERROR)

        return
    end

    local success, _ = pcall(_read_file, path, vim.schedule_wrap(_callback))

    if not success then
        vim.notify(string.format('Failed to read "%s" path. Cannot copy the logs.', path), vim.log.levels.ERROR)
    end
end

return M
