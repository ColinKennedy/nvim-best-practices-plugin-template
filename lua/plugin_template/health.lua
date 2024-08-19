--- Make sure `plugin_template` will work as expected.
---
--- At minimum, we validate that the user's configuration is correct. But other
--- checks can happen here if needed.
---
--- @module 'plugin_template.health'
---

local configuration_ = require("plugin_template._core.configuration")
local say_constant = require("plugin_template._commands.say.constant")

local M = {}

--- Access the attribute(s) within `data` from `items`.
---
--- @param data table<...> Some nested data to query. e.g. `{a={b={c=true}}}`.
--- @param items string[] Some attributes to query. e.g. `{"a", "b", "c"}`.
--- @return ...? # The found value, if any.
---
local function _get_value(data, items)
    local current = data

    for _, item in ipairs(items) do
        current = current[item]

        if not current then
            return nil
        end
    end

    return current
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

    local success, message = pcall(
        vim.validate,
        "commands.goodnight_moon.read.phrase",
        _get_value(data, { "commands", "goodnight_moon", "read", "phrase" }),
        "string"
    )

    if not success then
        table.insert(output, message)
    end

    success, message = pcall(vim.validate, {
        ["commands.hello_world.say.repeat"] = {
            _get_value(data, { "commands", "hello_world", "say", "repeat" }),
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
            _get_value(data, { "commands", "hello_world", "say", "style" }),
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
