--- Make sure `plugin_template` will work as expected.
---
--- At minimum, we validate that the user's configuration is correct. But other
--- checks can happen here if needed.
---
---@module 'plugin_template.health'
---

local configuration_ = require("plugin_template._core.configuration")
local say_constant = require("plugin_template._commands.hello_world.say.constant")
local tabler = require("plugin_template._core.tabler")
local texter = require("plugin_template._core.texter")
local vlog = require("plugin_template._vendors.vlog")

local M = {}

-- NOTE: This file is defer-loaded so it's okay to run this in the global scope
configuration_.initialize_data_if_needed()

---@class lualine.ColorHex
---    The table that Lualine expects when it sets colors.
---@field bg string
---    The background hex color. e.g. `"#444444"`.
---@field fg string
---    The text hex color. e.g. `"#DD0000"`.
---@field gui string
---    The background hex color. e.g. `"#444444"`.

--- Check if `value` has keys that it should not.
---
---@param value lualine.ColorHex
---
local function _has_extra_color_keys(value)
    local keys = { "bg", "fg", "gui" }

    for key, _ in pairs(value) do
        if not vim.tbl_contains(keys, key) then
            return true
        end
    end

    return false
end

--- Make sure `text` is a HEX code. e.g. `"#D0FF1A"`.
---
---@param text string An expected HEX code.
---@return boolean # If `text` matches, return `true`.
---
local function _is_hex_color(text)
    if type(text) ~= "string" then
        return false
    end

    return text:match("^#%x%x%x%x%x%x$") ~= nil
end

--- Add issues to `array` if there are errors.
---
--- Todo:
---     Once Neovim 0.10 is dropped, use the new function signature
---     for vim.validate to make this function cleaner.
---
---@param array string[]
---    All of the cumulated errors, if any.
---@param name string
---    The key to check for.
---@param value_creator fun(): any
---    A function that generates the value.
---@param expected string | fun(value: any): boolean
---    If `value_creator()` does not match `expected`, this error message is
---    shown to the user.
---@param message (string | boolean)?
---    If it's a string, it's the error message when
---    `value_creator()` does not match `expected`. When it's
---    `true`, it means it's okay for `value_creator()` not to match `expected`.
---
local function _append_validated(array, name, value_creator, expected, message)
    local success, value = pcall(value_creator)

    if not success then
        table.insert(array, value)

        return
    end

    local validated
    success, validated = pcall(vim.validate, {
        -- TODO: I think the Neovim type annotation is wrong. Once Neovim
        -- 0.10 is dropped let's just change this over to the new
        -- vim.validate signature.
        --
        ---@diagnostic disable-next-line: assign-type-mismatch
        [name] = { value, expected, message },
    })

    if not success then
        table.insert(array, validated)
    end
end

--- Check if `data` is a boolean under `key`.
---
---@param key string The configuration value that we are checking.
---@param data any The object to validate.
---@return string? # The found error message, if any.
---
local function _get_boolean_issue(key, data)
    local success, message = pcall(vim.validate, {
        [key] = {
            data,
            function(value)
                if value == nil then
                    -- NOTE: This value is optional so it's fine it if is not defined.
                    return true
                end

                return type(value) == "boolean"
            end,
            -- TODO: I think the Neovim type annotation is wrong. Once Neovim
            -- 0.10 is dropped let's just change this over to the new
            -- vim.validate signature.
            --
            ---@diagnostic disable-next-line: assign-type-mismatch
            "a boolean",
        },
    })

    if success then
        return nil
    end

    return message
end

--- Check all "cmdparse" values for issues.
---
---@param data plugin_template.Configuration All of the user's fallback settings.
---@return string[] # All found issues, if any.
---
local function _get_cmdparse_issues(data)
    local output = {}

    _append_validated(output, "cmdparse.auto_complete.display.help_flag", function()
        return tabler.get_value(data, { "cmdparse", "auto_complete", "display", "help_flag" })
    end, "boolean", true)

    return output
end

--- Check all "commands" values for issues.
---
---@param data plugin_template.Configuration All of the user's fallback settings.
---@return string[] # All found issues, if any.
---
local function _get_command_issues(data)
    local output = {}

    _append_validated(output, "commands.goodnight_moon.read.phrase", function()
        return tabler.get_value(data, { "commands", "goodnight_moon", "read", "phrase" })
    end, "string")

    _append_validated(output, "commands.hello_world.say.repeat", function()
        return tabler.get_value(data, { "commands", "hello_world", "say", "repeat" })
    end, function(value)
        return type(value) == "number" and value > 0
    end, "a number (value must be 1-or-more)")

    _append_validated(output, "commands.hello_world.say.style", function()
        return tabler.get_value(data, { "commands", "hello_world", "say", "style" })
    end, function(value)
        local choices = vim.tbl_keys(say_constant.Keyword.style)

        return vim.tbl_contains(choices, value)
    end, '"lowercase" or "uppercase"')

    return output
end

--- Check the contents of the "tools.lualine" configuration for any issues.
---
--- Issues include:
--- - Defining tools.lualine but it's not a table
--- - Or the table, which is `table<str, table<...>>`, has an incorrect value.
--- - The inner tables must also follow a specific structure.
---
---@param command string A supported `plugin_template` command. e.g. `"hello_world"`.
---@return string[] # All found issues, if any.
---
local function _get_lualine_command_issues(command, data)
    local output = {}

    _append_validated(output, string.format("tools.lualine.%s", command), function()
        return data
    end, function(value)
        if type(value) ~= "table" then
            return false
        end

        return true
    end, 'a table. e.g. { text="some text here" }')

    if not vim.tbl_isempty(output) then
        return output
    end

    _append_validated(output, string.format("tools.lualine.%s.text", command), function()
        return tabler.get_value(data, { "text" })
    end, function(value)
        if type(value) ~= "string" then
            return false
        end

        return true
    end, 'a string. e.g. "some text here"')

    _append_validated(output, string.format("tools.lualine.%s.color", command), function()
        return tabler.get_value(data, { "color" })
    end, function(value)
        if value == nil then
            -- NOTE: It's okay for this value to be undefined because
            -- we define a fallback for the user.
            --
            return true
        end

        local type_ = type(value)

        if type_ == "string" then
            -- NOTE: We assume that there is a linkable highlight group
            -- with the name of `value` already or one that will exist.
            --
            return true
        end

        if type_ == "table" then
            if value.bg ~= nil and not _is_hex_color(value.bg) then
                return false
            end

            if value.fg ~= nil and not _is_hex_color(value.fg) then
                return false
            end

            if value.gui ~= nil and type(value.gui) ~= "string" then
                return false
            end

            if _has_extra_color_keys(value) then
                return false
            end

            return true
        end

        return false
    end, 'a table. e.g. {fg="#000000", bg="#FFFFFF", gui="effect"}')

    return output
end

--- Check all "tools.lualine" values for issues.
---
---@param data plugin_template.Configuration All of the user's fallback settings.
---@return string[] # All found issues, if any.
---
local function _get_lualine_issues(data)
    local output = {}

    local lualine = tabler.get_value(data, { "tools", "lualine" })

    _append_validated(output, "tools.lualine", function()
        return lualine
    end, function(value)
        if type(value) ~= "table" then
            return false
        end

        return true
    end, "a table. e.g. { goodnight_moon = {...}, hello_world = {...} }")

    if not vim.tbl_isempty(output) then
        return output
    end

    for _, command in ipairs({ "arbitrary_thing", "goodnight_moon", "hello_world" }) do
        local value = tabler.get_value(lualine, { command })

        -- NOTE: We have fallback values so it's okay if the value is nil.
        if value ~= nil then
            local issues = _get_lualine_command_issues(command, value)

            vim.list_extend(output, issues)
        end
    end

    return output
end

--- Check if logging configuration `data` has any issues.
---
---@param data plugin_template.LoggingConfiguration The user's logger settings.
---@return string[] # All of the found issues, if any.
---
local function _get_logging_issues(data)
    local output = {}

    _append_validated(output, "logging", function()
        return data
    end, function(value)
        if type(value) ~= "table" then
            return false
        end

        return true
    end, 'a table. e.g. { level = "info", ... }')

    if not vim.tbl_isempty(output) then
        return output
    end

    _append_validated(output, "logging.level", function()
        return data.level
    end, function(value)
        if type(value) ~= "string" then
            return false
        end

        if not vim.tbl_contains({ "trace", "debug", "info", "warn", "error", "fatal" }, value) then
            return false
        end

        return true
    end, 'an enum. e.g. "trace" | "debug" | "info" | "warn" | "error" | "fatal"')

    local message = _get_boolean_issue("logging.use_console", data.use_console)

    if message ~= nil then
        table.insert(output, message)
    end

    message = _get_boolean_issue("logging.use_file", data.use_file)

    if message ~= nil then
        table.insert(output, message)
    end

    return output
end

--- Check all "tools.lualine" values for issues.
---
---@param data plugin_template.Configuration All of the user's fallback settings.
---@return string[] # All found issues, if any.
---
local function _get_telescope_issues(data)
    local output = {}

    local telescope = tabler.get_value(data, { "tools", "telescope" })

    _append_validated(output, "tools.telescope", function()
        return telescope
    end, function(value)
        if type(value) ~= "table" then
            return false
        end

        return true
    end, "a table. e.g. { goodnight_moon = {...}, hello_world = {...}}")

    if not vim.tbl_isempty(output) then
        return output
    end

    _append_validated(output, "tools.telescope.goodnight_moon", function()
        return telescope.goodnight_moon
    end, function(value)
        if value == nil then
            return true
        end

        if type(value) ~= "table" then
            return false
        end

        for _, item in ipairs(value) do
            if not texter.is_string_list(item) then
                return false
            end

            if #item ~= 2 then
                return false
            end
        end

        return true
    end, 'a table. e.g. { {"Book", "Author"} }')

    _append_validated(output, "tools.telescope.hello_world", function()
        return telescope.hello_world
    end, function(value)
        if value == nil then
            return true
        end

        if type(value) ~= "table" then
            return false
        end

        return texter.is_string_list(value)
    end, 'a table. e.g. { "Hello", "Hi", ...} }')

    return output
end

--- Check `data` for problems and return each of them.
---
---@param data plugin_template.Configuration? All extra customizations for this plugin.
---@return string[] # All found issues, if any.
---
function M.get_issues(data)
    if not data or vim.tbl_isempty(data) then
        data = configuration_.resolve_data(vim.g.plugin_template_configuration)
    end

    local output = {}
    vim.list_extend(output, _get_cmdparse_issues(data))
    vim.list_extend(output, _get_command_issues(data))

    local logging = data.logging

    if logging ~= nil then
        vim.list_extend(output, _get_logging_issues(data.logging))
    end

    local lualine = tabler.get_value(data, { "tools", "lualine" })

    if lualine ~= nil then
        vim.list_extend(output, _get_lualine_issues(data))
    end

    local telescope = tabler.get_value(data, { "tools", "telescope" })

    if telescope ~= nil then
        vim.list_extend(output, _get_telescope_issues(data))
    end

    return output
end

--- Make sure `data` will work for `plugin_template`.
---
---@param data plugin_template.Configuration? All extra customizations for this plugin.
---
function M.check(data)
    vlog.debug("Running plugin-template health check.")

    vim.health.start("Configuration")

    local issues = M.get_issues(data)

    if vim.tbl_isempty(issues) then
        vim.health.ok("Your vim.g.plugin_template_configuration variable is great!")
    end

    for _, issue in ipairs(issues) do
        vim.health.error(issue)
    end
end

return M
