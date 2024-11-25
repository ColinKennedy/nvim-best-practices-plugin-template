--- A generalized logging for Lua. It's similar to Python's built-in logger.
---
---@module 'plugin_template._vendors.aggro.logging'
---

---@class aggro.logging.LoggerOptions
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
---@field use_neovim_commands boolean
---    If `true`, allow logs to submit as Neovim commands. If `false`, only
---    built-in Lua commands will be used. This is useful if you want to log
---    within a libuv thread and don't want to call `vim.schedule()`.

---@class aggro.logging._LevelMode Data related to `level` to consider.
---@field highlight string The Neovim highlight group name used to colorize the logs.
---@field level string The associated level for this object.
---@field name string The name of the level, e.g. `"info"`.

local _P = {}
local M = {}

local _LEVELS = { trace = 10, debug = 20, info = 30, warn = 40, error = 50, fatal = 60 }

--- Suggest a default level for all loggers.
---
--- Raises:
---     If `$LOG_LEVEL` is set but it is empty or a non-number.
---
---@param default number The 1-or-more level to use for all loggers.
---@return number # The found suggestion.
---
function _P.get_initial_default_level(default)
    local level_text = os.getenv("LOG_LEVEL")

    if not level_text then
        return default
    end

    local level = tonumber(level_text)

    if level then
        return level
    end

    error(string.format('LOG_LEVEL "%s" must be a number.', level_text), 0)
end

local _MODES = {
    debug = { name = "debug", highlight = "Comment" },
    error = { name = "error", highlight = "ErrorMsg" },
    fatal = { name = "fatal", highlight = "ErrorMsg" },
    info = { name = "info", highlight = "None" },
    trace = { name = "trace", highlight = "Comment" },
    warning = { name = "warning", highlight = "WarningMsg" },
}

M._DEFAULTS = {
    float_precision = 0.01,
    highlights = true,
    level = _P.get_initial_default_level(_LEVELS.info),
    output_path = nil,
    use_console = true,
    use_file = true,
    use_highlights = true,
    use_neovim_commands = true,
}

local _ROOT_NAME = "__ROOT__"

---@type table<string, aggro.logging.Logger>
M._LOGGERS = {}

---@class aggro.logging.Logger
M.Logger = {
    __tostring = function(logger)
        return string.format("aggro.logging.Logger({names=%s})", vim.inspect(logger.name))
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

--- Format a template string and log it according to `level` and `mode`.
---
---@param level number
---    The level for the log (debug, info, etc).
---@param mode aggro.logging._LevelMode
---    Data related to `level` to consider.
---@param ... any
---    Arguments to pass to `message_maker`. It's expected that the first
---    argument is a template like `"some thing to %s replace %d here"`, and
---    then the next arguments might be `"asdf"` and `8`, to fill in the template.
---
function M.Logger:_format_and_log_at_level(level, mode, ...)
    local passed = { ... }

    return self:_log_at_level(level, mode, function()
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

--- Decide whether or not to log and how.
---
---@param level number The level for the log (debug, info, etc).
---@param mode aggro.logging._LevelMode Data related to `level` to consider.
---@param message_maker fun(...: any): string The function that, when called, creates a log message.
---@param ... any Arguments to pass to `message_maker`.
---
function M.Logger:_log_at_level(level, mode, message_maker, ...)
    ---@type number | string
    local current_level = self.level

    if type(current_level) == "string" then
        ---@diagnostic disable-next-line: cast-local-type
        current_level = tonumber(_LEVELS[current_level])
    end

    if level < current_level then
        return
    end

    local nameupper = mode.name:upper()

    local message = message_maker(...)
    local info = debug.getinfo(2, "Sl")
    local lineinfo = info.short_src .. ":" .. info.currentline

    if self._use_console then
        local console_string = string.format("[%-6s%s] %s: %s", nameupper, os.date("%H:%M:%S"), lineinfo, message)

        if not self.use_neovim_commands then
            local split_console = vim.split(console_string, "\n")

            for _, v in ipairs(split_console) do
                print(string.format("[%s] %s", self.name, vim.fn.escape(v, '"')))
            end
        else
            if self.use_highlights and mode.highlight then
                vim.cmd(string.format("echohl %s", mode.highlight))
            end

            local split_console = vim.split(console_string, "\n")

            for _, v in ipairs(split_console) do
                vim.cmd(string.format([[echom "[%s] %s"]], self.name, vim.fn.escape(v, '"')))
            end

            if self.use_highlights and mode.highlight then
                vim.cmd("echohl NONE")
            end
        end
    end

    if self.use_file then
        if not self._output_path then
            error('Cannot write Logger message to file, no output path was given.', 0)
        end

        local handler = io.open(self._output_path, "a")

        if not handler then
            vim.notify(string.format('Unable to log to "%s" path.', self._output_path), vim.log.levels.ERROR)
        else
            handler:write(string.format("[%-6s%s] %s: %s\n", nameupper, os.date(), lineinfo, message))
            handler:close()
        end
    end
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

--- Send a message that is intended for developers to the logger.
---
---@param ... any Any arguments.
---
function M.Logger:debug(...)
    self:_log_at_level(_LEVELS.debug, _MODES.debug, function(...)
        return self:_make_string(...)
    end, ...)
end

--- Send a "we could not recover from some issue" message to the logger.
---
---@param ... any Any arguments.
---
function M.Logger:error(...)
    self:_log_at_level(_LEVELS.error, _MODES.error, function(...)
        return self:_make_string(...)
    end, ...)
end

--- Send a "this issue affects multiple systems. It's a really bad error" message to the logger.
---
---@param ... any Any arguments.
---
function M.Logger:fatal(...)
    self:_log_at_level(_LEVELS.fatal, _MODES.fatal, function(...)
        return self:_make_string(...)
    end, ...)
end

--- Send a message that is intended for developers to the logger.
---
---@param ... any Any arguments.
---
function M.Logger:fmt_debug(...)
    self:_format_and_log_at_level(_LEVELS.debug, _MODES.debug, ...)
end

--- Send a "we could not recover from some issue" message to the logger.
---
---@param ... any Any arguments.
---
function M.Logger:fmt_error(...)
    self:_format_and_log_at_level(_LEVELS.error, _MODES.error, ...)
end

--- Send a "this issue affects multiple systems. It's a really bad error" message to the logger.
---
---@param ... any Any arguments.
---
function M.Logger:fmt_fatal(...)
    self:_format_and_log_at_level(_LEVELS.fatal, _MODES.fatal, ...)
end

--- Send a user-facing message to the logger.
---
---@param ... any Any arguments.
---
function M.Logger:fmt_info(...)
    self:_format_and_log_at_level(_LEVELS.info, _MODES.info, ...)
end

--- Send a "this might be an issue or we recovered from an error" message to the logger.
---
---@param ... any Any arguments.
---
function M.Logger:fmt_warning(...)
    self:_format_and_log_at_level(_LEVELS.warning, _MODES.warning, ...)
end

--- Send a user-facing message to the logger.
---
---@param ... any Any arguments.
---
function M.Logger:info(...)
    self:_log_at_level(_LEVELS.info, _MODES.info, function(...)
        return self:_make_string(...)
    end, ...)
end

--- Send a "this might be an issue or we recovered from an error" message to the logger.
---
---@param ... any Any arguments.
---
function M.Logger:warning(...)
    self:_log_at_level(_LEVELS.warning, _MODES.warning, function(...)
        return self:_make_string(...)
    end, ...)
end

--- Create a new logger according to `options`.
---
---@param options aggro.logging.LoggerOptions The logger to create.
---@return aggro.logging.Logger # The created instance.
---
function M.Logger.new(options)
    ---@class aggro.logging.Logger
    local self = setmetatable({}, M.Logger)

    self.level = options.level
    self.name = options.name
    self.use_file = options.use_file
    self.use_highlights = options.use_highlights
    self.use_neovim_commands = options.use_neovim_commands

    self._float_precision = options.float_precision
    self._use_console = options.use_console
    ---@type string?
    self._output_path = options.output_path

    if not self._output_path and self.use_neovim_commands then
        self._output_path = vim.fs.joinpath(vim.api.nvim_call_function("stdpath", { "data" }), "default.log")
    end

    return self
end

---@return string? # The path on-disk where logs will be written to.
function M.Logger:get_log_path()
    return self._output_path
end

--- Find an existing logger with `name` or create one if it does not exist already.
---
---@param options aggro.logging.LoggerOptions | string The logger to create.
---@return aggro.logging.Logger # The created instance.
---
function M.get_logger(options)
    if type(options) == "string" then
        ---@diagnostic disable-next-line: missing-fields
        options = { name = options }
    end

    options = vim.tbl_deep_extend("force", M._DEFAULTS, options or {})
    local name = options.name

    if not name then
        name = _ROOT_NAME
    end

    if M._LOGGERS[name] then
        return M._LOGGERS[name]
    end

    M._LOGGERS[name] = M.Logger.new(options)

    return M._LOGGERS[name]
end

return M
