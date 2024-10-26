-- vlog.lua
--
-- Inspired by rxi/log.lua
-- Modified by tjdevries and can be found at github.com/tjdevries/vlog.nvim
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.

-- User configuration section
local default_config = {
    -- Name of the plugin. Prepended to log messages
    plugin = "plugin_template",

    -- Should print the output to neovim while running
    use_console = true,

    -- Should highlighting be used in console (using echohl)
    highlights = true,

    -- Should write to a file
    use_file = true,

    -- Any messages above this level will be logged.
    level = "info",

    -- Level configuration
    modes = {
        { name = "trace", hl = "Comment" },
        { name = "debug", hl = "Comment" },
        { name = "info", hl = "None" },
        { name = "warn", hl = "WarningMsg" },
        { name = "error", hl = "ErrorMsg" },
        { name = "fatal", hl = "ErrorMsg" },
    },

    -- Define this path to redirect the log file to wherever you need it to go
    output_path = nil,

    -- Can limit the number of decimals displayed for floats
    float_precision = 0.01,
}

-- {{{ NO NEED TO CHANGE
local log = {}

---@diagnostic disable-next-line: deprecated
local unpack = unpack or table.unpack

local _LEVEL_NUMBER_TO_LEVEL_NAME = {
    [vim.log.levels.DEBUG] = "debug",
    [vim.log.levels.ERROR] = "error",
    [vim.log.levels.INFO] = "info",
    [vim.log.levels.TRACE] = "trace",
    [vim.log.levels.WARN] = "warn",
}

log.new = function(config, standalone)
    config = vim.tbl_deep_extend("force", default_config, config)
    config.level = _LEVEL_NUMBER_TO_LEVEL_NAME[config.level] or config.level

    local obj
    if standalone then
        obj = log
    else
        obj = {}
    end

    obj._is_logging_to_file_enabled = config.use_file

    obj._output_path = config.output_path
        or vim.fs.joinpath(vim.api.nvim_call_function("stdpath", { "data" }), string.format("%s.log", config.plugin))

    local levels = {}
    for i, v in ipairs(config.modes) do
        levels[v.name] = i
    end

    local round = function(x, increment)
        increment = increment or 1
        x = x / increment
        return (x > 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)) * increment
    end

    local make_string = function(...)
        local t = {}
        for i = 1, select("#", ...) do
            local x = select(i, ...)

            if type(x) == "number" and config.float_precision then
                x = tostring(round(x, config.float_precision))
            elseif type(x) == "table" then
                x = vim.inspect(x)
            else
                x = tostring(x)
            end

            t[#t + 1] = x
        end
        return table.concat(t, " ")
    end

    local log_at_level = function(level, level_config, message_maker, ...)
        -- Return early if we're below the config.level
        if level < levels[config.level] then
            return
        end
        local nameupper = level_config.name:upper()

        local msg = message_maker(...)
        local info = debug.getinfo(2, "Sl")
        local lineinfo = info.short_src .. ":" .. info.currentline

        -- Output to console
        if config.use_console then
            local console_string = string.format("[%-6s%s] %s: %s", nameupper, os.date("%H:%M:%S"), lineinfo, msg)

            if config.highlights and level_config.hl then
                vim.cmd(string.format("echohl %s", level_config.hl))
            end

            local split_console = vim.split(console_string, "\n")
            for _, v in ipairs(split_console) do
                vim.cmd(string.format([[echom "[%s] %s"]], config.plugin, vim.fn.escape(v, '"')))
            end

            if config.highlights and level_config.hl then
                vim.cmd("echohl NONE")
            end
        end

        -- Output to log file
        if obj._is_logging_to_file_enabled then
            local fp = io.open(obj._output_path, "a")

            if not fp then
                vim.notify(string.format('Unable to log to "%s" path.', obj._output_path), vim.log.levels.ERROR)
            else
                local str = string.format("[%-6s%s] %s: %s\n", nameupper, os.date(), lineinfo, msg)
                fp:write(str)
                fp:close()
            end
        end
    end

    for i, x in ipairs(config.modes) do
        obj[x.name] = function(...)
            return log_at_level(i, x, make_string, ...)
        end

        obj[("fmt_%s"):format(x.name)] = function(...)
            local passed = { ... }
            return log_at_level(i, x, function()
                local fmt = table.remove(passed, 1)
                local inspected = {}
                for _, v in ipairs(passed) do
                    if type(v) == "string" then
                        table.insert(inspected, v)
                    else
                        table.insert(inspected, vim.inspect(v))
                    end
                end
                return string.format(fmt, unpack(inspected))
            end)
        end
    end

    obj["is_logging_to_file"] = function()
        return obj._is_logging_to_file_enabled
    end

    obj["get_log_path"] = function()
        return obj._output_path
    end

    obj["toggle_file_logging"] = function()
        obj._is_logging_to_file_enabled = not obj._is_logging_to_file_enabled
    end
end

return log
