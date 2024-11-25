-- -- vlog.lua
-- --
-- -- Inspired by rxi/log.lua
-- -- Modified by tjdevries and can be found at github.com/tjdevries/vlog.nvim
-- --
-- -- This library is free software; you can redistribute it and/or modify it
-- -- under the terms of the MIT license. See LICENSE for details.
--
-- -- User configuration section
-- local default_config = {
--     -- Name of the plugin. Prepended to log messages
--     plugin = "plugin_template",
--
--     -- Should print the output to neovim while running
--     use_console = true,
--
--     -- Should highlighting be used in console (using echohl)
--     highlights = true,
--
--     -- Should write to a file
--     use_file = true,
--
--     -- Any messages above this level will be logged.
--     level = "info",
--
--     -- Level configuration
--     modes = {
--         { name = "trace", hl = "Comment" },
--         { name = "debug", hl = "Comment" },
--         { name = "info", hl = "None" },
--         { name = "warn", hl = "WarningMsg" },
--         { name = "error", hl = "ErrorMsg" },
--         { name = "fatal", hl = "ErrorMsg" },
--     },
--
--     -- Define this path to redirect the log file to wherever you need it to go
--     output_path = nil,
--
--     -- Can limit the number of decimals displayed for floats
--     float_precision = 0.01,
-- }
--
-- -- {{{ NO NEED TO CHANGE
-- local log = {}
--
-- ---@diagnostic disable-next-line: deprecated
-- local unpack = unpack or table.unpack
--
-- local _LEVEL_NUMBER_TO_LEVEL_NAME = {
--     [vim.log.levels.DEBUG] = "debug",
--     [vim.log.levels.ERROR] = "error",
--     [vim.log.levels.INFO] = "info",
--     [vim.log.levels.TRACE] = "trace",
--     [vim.log.levels.WARN] = "warn",
--     fatal = "fatal",
-- }
--
-- log.new = function(config, standalone)
--     config = vim.tbl_deep_extend("force", default_config, config)
--     config.level = _LEVEL_NUMBER_TO_LEVEL_NAME[config.level] or config.level
--
--     local obj
--     if standalone then
--         obj = log
--     else
--         obj = {}
--     end
--
--     obj._is_logging_to_file_enabled = config.use_file
--
--     obj._output_path = config.output_path
--         or vim.fs.joinpath(vim.api.nvim_call_function("stdpath", { "data" }), string.format("%s.log", config.plugin))
--
--     local levels = {}
--     for i, v in ipairs(config.modes) do
--         levels[v.name] = i
--     end
--
--     local round = function(x, increment)
--         increment = increment or 1
--         x = x / increment
--         return (x > 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)) * increment
--     end
--
--     local make_string = function(...)
--         local t = {}
--         for i = 1, select("#", ...) do
--             local x = select(i, ...)
--
--             if type(x) == "number" and config.float_precision then
--                 x = tostring(round(x, config.float_precision))
--             elseif type(x) == "table" then
--                 x = vim.inspect(x)
--             else
--                 x = tostring(x)
--             end
--
--             t[#t + 1] = x
--         end
--         return table.concat(t, " ")
--     end
--
--     local log_at_level = function(level, level_config, message_maker, ...)
--         -- Return early if we're below the config.level
--         if level < levels[config.level] then
--             return
--         end
--         local nameupper = level_config.name:upper()
--
--         local message = message_maker(...)
--         local info = debug.getinfo(2, "Sl")
--         local lineinfo = info.short_src .. ":" .. info.currentline
--
--         -- Output to console
--         if config.use_console then
--             local console_string = string.format("[%-6s%s] %s: %s", nameupper, os.date("%H:%M:%S"), lineinfo, message)
--
--             if config.highlights and level_config.hl then
--                 vim.cmd(string.format("echohl %s", level_config.hl))
--             end
--
--             local split_console = vim.split(console_string, "\n")
--             for _, v in ipairs(split_console) do
--                 vim.cmd(string.format([[echom "[%s] %s"]], config.plugin, vim.fn.escape(v, '"')))
--             end
--
--             if config.highlights and level_config.hl then
--                 vim.cmd("echohl NONE")
--             end
--         end
--
--         -- Output to log file
--         if obj._is_logging_to_file_enabled then
--             local fp = io.open(obj._output_path, "a")
--
--             if not fp then
--                 vim.notify(string.format('Unable to log to "%s" path.', obj._output_path), vim.log.levels.ERROR)
--             else
--                 local str = string.format("[%-6s%s] %s: %s\n", nameupper, os.date(), lineinfo, message)
--                 fp:write(str)
--                 fp:close()
--             end
--         end
--     end
--
--     for i, x in ipairs(config.modes) do
--         obj[x.name] = function(...)
--             return log_at_level(i, x, make_string, ...)
--         end
--
--         obj[("fmt_%s"):format(x.name)] = function(...)
--             local passed = { ... }
--             return log_at_level(i, x, function()
--                 local fmt = table.remove(passed, 1)
--                 local inspected = {}
--                 for _, v in ipairs(passed) do
--                     if type(v) == "string" then
--                         table.insert(inspected, v)
--                     else
--                         table.insert(inspected, vim.inspect(v))
--                     end
--                 end
--                 return string.format(fmt, unpack(inspected))
--             end)
--         end
--     end
--
--     obj["is_logging_to_file"] = function()
--         return obj._is_logging_to_file_enabled
--     end
--
--     obj["get_log_path"] = function()
--         return obj._output_path
--     end
--
--     obj["toggle_file_logging"] = function()
--         obj._is_logging_to_file_enabled = not obj._is_logging_to_file_enabled
--     end
-- end
--
-- return log

---@class vlog.LoggerOptions
---    All of the customizations a person can make to a logger instance.
---@field float_precision number
---    A positive value (max of 1) to indicate the rounding precision. e.g.
---    0.01 rounds to every hundredths.
---@field level "trace" | "debug" | "info" | "warn" | "error" | "fatal"
---    The minimum severity needed for this logger instance to output a log.
---@field name string
---    An identifier for this logger.
---@field output_path string
---    A path on-disk where logs are written to, if any.
---@field use_console boolean
---    If `true`, logs are printed to the terminal / console.
---@field use_file boolean
---    If `true`, logs are written to `output_path`.
---@field use_highlights boolean
---    If `true`, logs are colorful. If `false`, they're mono-colored text.

-- TODO: Make sure colors work as expected

---@class vlog._LevelMode Data related to `level` to consider.
---@field highlight string The Neovim highlight group name used to colorize the logs.
---@field level string The associated level for this object.

local _P = {}
local M = {}

M._DEFAULTS = {
    float_precision = 0.01,
    highlights = true,
    level = "info",
    modes = {
        { name = "trace", highlight = "Comment" },
        { name = "debug", highlight = "Comment" },
        { name = "info", highlight = "None" },
        { name = "warn", highlight = "WarningMsg" },
        { name = "error", highlight = "ErrorMsg" },
        { name = "fatal", highlight = "ErrorMsg" },
    },
    output_path = nil,
    use_console = true,
    use_file = true,
    use_highlights = true,
}

local _LEVELS = {}

for index, mode in ipairs(M._DEFAULTS.modes) do
    _LEVELS[mode.name] = index
end

local _ROOT_NAME = "__ROOT__"

---@type table<string, vlog.Logger>
M._LOGGERS = {}

---@class vlog.Logger
M.Logger = {
    __tostring = function(logger)
        return string.format("vlog.Logger({names=%s})", vim.inspect(logger.name))
    end,
}
M.Logger.__index = M.Logger


-- TODO: Replace the timing function that rounds precision with this rounder, instead.
--- Approximate (round) `value` according to `increment`.
---
---@param value number
---    Some float to round / crop.
---@param increment number
---    A positive value (max of 1) to indicate the rounding precision. e.g.
---    0.01 rounds to every hundredths.
---@return number
---    The founded value.
---
function _P.round(value, increment)
    increment = increment or 1
    value = value / increment

    return (value > 0 and math.floor(value + 0.5) or math.ceil(value - 0.5)) * increment
end


--- Serialize log arguments into strings and merge them into a single log message.
---
---@param ... any The arguments to consider.
---@return string # The genreated message.
---
function M.Logger:_make_string(...)
    local characters = {}

    for index = 1, select("#", ...) do
        local text = select(index, ...)

        if type(text) == "number" and self._float_precision then
            text = tostring(_P.round(text, self._float_precision))
        elseif type(text) == "table" then
            text = vim.inspect(text)
        else
            text = tostring(text)
        end

        characters[#characters + 1] = text
    end

    return table.concat(characters, " ")
end


--- Create a new logger according to `options`.
---
---@param options vlog.LoggerOptions | string The logger to create.
---@return vlog.Logger # The created instance.
---
function M.Logger.new(options)
    if type(options) == "string" then
        options = {name=options}
    end
    options = vim.tbl_deep_extend("force", M._DEFAULTS, options or {})

    ---@class vlog.Logger
    local self = setmetatable({}, M.Logger)

    self._float_precision = options.float_precision
    self._use_console = options.use_console
    self._use_file = options.use_file
    self._use_highlights = options.use_highlights
    self._output_path = options.output_path
        or vim.fs.joinpath(vim.api.nvim_call_function("stdpath", { "data" }), "default.log")
    self.level = options.level
    self.name = options.name

    for index, mode in ipairs(options.modes) do
        self[mode.name] = function(...)
            return self:_log_at_level(index, mode, function(...) return self:_make_string(...) end, ...)
        end

        self[("fmt_%s"):format(mode.name)] = function(...)
            local passed = { ... }

            return self:_log_at_level(index, mode, function()
                local template = table.remove(passed, 1)
                local inspected = {}

                for _, value in ipairs(passed) do
                    if type(value) == "string" then
                        table.insert(inspected, value)
                    else
                        table.insert(inspected, vim.inspect(value))
                    end
                end

                return string.format(template, unpack(inspected))
            end)
        end
    end

    return self
end

--- Decide whether or not to log and how.
---
---@param level number The level for the log (debug, info, etc).
---@param mode vlog._LevelMode Data related to `level` to consider.
---@param message_maker fun(...: any): string The function that, when called, creates a log message.
---@param ... any Arguments to pass to `message_maker`.
---
function M.Logger:_log_at_level(level, mode, message_maker, ...)
    if level < _LEVELS[self.level] then
        return
    end

    local nameupper = mode.name:upper()

    local message = message_maker(...)
    local info = debug.getinfo(2, "Sl")
    local lineinfo = info.short_src .. ":" .. info.currentline

    if self._use_console then
        local console_string = string.format("[%-6s%s] %s: %s", nameupper, os.date("%H:%M:%S"), lineinfo, message)

        if self._use_highlights and mode.highlight then
            vim.cmd(string.format("echohl %s", mode.highlight))
        end

        local split_console = vim.split(console_string, "\n")
        for _, v in ipairs(split_console) do
            vim.cmd(string.format([[echom "[%s] %s"]], self.name, vim.fn.escape(v, '"')))
        end

        if self._use_highlights and mode.highlight then
            vim.cmd("echohl NONE")
        end
    end

    if self._use_file then
        local handler = io.open(self._output_path, "a")

        if not handler then
            vim.notify(string.format('Unable to log to "%s" path.', self._output_path), vim.log.levels.ERROR)
        else
            handler:write(string.format("[%-6s%s] %s: %s\n", nameupper, os.date(), lineinfo, message))
            handler:close()
        end
    end
end

---@return string # The path on-disk where logs will be written to.
function M.Logger:get_log_path()
    return self._output_path
end

--- Find an existing logger with `name` or create one if it does not exist already.
---
---@param name string The logger name. e.g. `"foo.bar"`.
---@return vlog.Logger # The created instance.
---
function M.get_logger(name)
    if not name then
        name = _ROOT_NAME
    end

    if M._LOGGERS[name] then
        return M._LOGGERS[name]
    end

    M._LOGGERS[name] = M.Logger.new(name)

    return M._LOGGERS[name]
end

return M
