--- Make sure `plugin_template` will work as expected.
---
--- At minimum, we validate that the user's configuration is correct. But other
--- checks can happen here if needed.
---
--- @module 'plugin_template.health'
---

local configuration_ = require("plugin_template._core.configuration")
local say_constant = require("plugin_template._commands.hello_world.say.constant")
local tabler = require("plugin_template._core.tabler")

local M = {}

--- Check all "commands" values for completeness.
---
--- @param data PluginTemplateConfiguration All of the user's fallback settings.
--- @return string[] # All found issues, if any.
---
local function _get_command_issues(data)
    local output = {}

    local success, message = pcall(
        vim.validate,
        "commands.goodnight_moon.read.phrase",
        tabler.get_value(data, { "commands", "goodnight_moon", "read", "phrase" }),
        "string"
    )

    if not success then
        table.insert(output, message)
    end

    success, message = pcall(vim.validate, {
        ["commands.hello_world.say.repeat"] = {
            tabler.get_value(data, { "commands", "hello_world", "say", "repeat" }),
            function(value)
                return type(value) == "number" and value > 0
            end,
            "a number (value must be 1-or-more)",
        },
    })

    if not success then
        table.insert(output, message)
    end

    success, message = pcall(vim.validate, {
        ["commands.hello_world.say.style"] = {
            tabler.get_value(data, { "commands", "hello_world", "say", "style" }),
            function(value)
                local choices = vim.tbl_keys(say_constant.Keyword.style)

                return vim.tbl_contains(choices, value)
            end,
            '"lowercase" or "uppercase"',
        },
    })

    if not success then
        table.insert(output, message)
    end

    return output
end

--- Check the contents of the "tools.lualine" configuration for any issues.
---
--- Issues include:
--- - Defining tools.lualine but it's not a table
--- - Or the table, which is `table<str, table<...>>`, has an incorrect value.
--- - The inner tables must also follow a specific structure.
---
--- @param command string A supported `plugin_template` command. e.g. `"hello_world"`.
--- @return string[] # All found issues, if any.
---
local function _get_lualine_command_issues(command, data)
    local success, message = pcall(vim.validate, {
        [string.format("tools.lualine.%s", command)] = {
            data,
            function(value)
                if type(value) ~= "table" then
                    return false
                end

                return true
            end,
            'a table. e.g. { text="some text here" }',
        },
    })

    if not success then
        return { message }
    end

    local output = {}

    success, message = pcall(vim.validate, {
        [string.format("tools.lualine.%s.text", command)] = {
            tabler.get_value(data, { "text" }),
            function(value)
                if type(value) ~= "string" then
                    return false
                end

                return true
            end,
            'a string. e.g. "some text here"',
        },
    })

    if not success then
        table.insert(output, message)
    end

    success, message = pcall(vim.validate, {
        [string.format("tools.lualine.%s.color", command)] = {
            tabler.get_value(data, { "color" }),
            function(value)
                if value == nil then
                    -- NOTE: It's okay for this value to be undefined because
                    -- we define a fallback for the user.
                    --
                    return true
                end

                if type(value) ~= "table" then
                    return false
                end

                return true
            end,
            'a table. e.g. {fg="#000000", bg="#FFFFFF"}, {link="Title"}, etc',
        },
    })

    if not success then
        table.insert(output, message)
    end

    return output
end

--- Check all "tools.lualine" values for completeness.
---
--- @param data PluginTemplateConfiguration All of the user's fallback settings.
--- @return string[] # All found issues, if any.
---
local function _get_lualine_issues(data)
    local output = {}

    local lualine = tabler.get_value(data, { "tools", "lualine" })

    local success, message = pcall(vim.validate, {
        ["tools.lualine"] = {
            lualine,
            function(value)
                if type(value) ~= "table" then
                    return false
                end

                return true
            end,
            "a table. e.g. { goodnight_moon = {...}, hello_world = {...} }",
        },
    })

    if not success then
        table.insert(output, message)

        return output
    end

    if not lualine or vim.tbl_isempty(lualine) then
        return output
    end

    for _, command in ipairs({ "goodnight_moon", "hello_world" }) do
        local issues = _get_lualine_command_issues(command, tabler.get_value(lualine, { command }))

        vim.list_extend(output, issues)
    end

    return output
end

--- Check `data` for problems and return each of them.
---
--- @param data PluginTemplateConfiguration? All extra customizations for this plugin.
--- @return string[] # All found issues, if any.
---
function M.get_issues(data)
    if not data or vim.tbl_isempty(data) then
        data = configuration_.resolve_data(vim.g.plugin_template_configuration)
    end

    local output = {}
    vim.list_extend(output, _get_command_issues(data))

    local lualine = tabler.get_value(data, { "tools", "lualine" })

    if lualine ~= nil then
        vim.list_extend(output, _get_lualine_issues(data))
    end

    return output
end

--- Make sure `data` will work for `plugin_template`.
---
--- @param data PluginTemplateConfiguration? All extra customizations for this plugin.
---
function M.check(data)
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
