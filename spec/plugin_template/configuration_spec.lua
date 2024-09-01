--- Make sure configuration health checks succeed or fail where they should.
---
---@module 'plugin_template.configuration_spec'
---

local configuration_ = require("plugin_template._core.configuration")
local health = require("plugin_template.health")
local tabler = require("plugin_template._core.tabler")

local mock_vim = require("test_utilities.mock_vim")

--- Make sure `data`, whether undefined, defined, or partially defined, is broken.
---
---@param data plugin_template.Configuration? The user customizations, if any.
---@param messages string[] All found, expected error messages.
---
local function _assert_bad(data, messages)
    data = configuration_.resolve_data(data)
    local issues = health.get_issues(data)

    if vim.tbl_isempty(issues) then
        error(string.format('Test did not fail. Configuration "%s is valid.', vim.inspect(data)))

        return
    end

    assert.same(messages, issues)
end

--- Make sure `data`, whether undefined, defined, or partially defined, works.
---
---@param data plugin_template.Configuration? The user customizations, if any.
---
local function _assert_good(data)
    data = configuration_.resolve_data(data)
    local issues = health.get_issues(data)

    if vim.tbl_isempty(issues) then
        return
    end

    error(
        string.format(
            'Test did not succeed. Configuration "%s fails with "%s" issues.',
            vim.inspect(data),
            vim.inspect(issues)
        )
    )
end

describe("default", function()
    it("works with an #empty configuration", function()
        _assert_good({})
        _assert_good()
    end)

    it("works with a fully defined, custom configuration", function()
        _assert_good({
            commands = {
                goodnight_moon = {
                    read = { phrase = "The Origin of Consciousness in the Breakdown of the Bicameral Mind" },
                },
                hello_world = { say = { ["repeat"] = 12, style = "uppercase" } },
            },
        })
    end)

    it("works with the default configuration", function()
        _assert_good({
            commands = {
                goodnight_moon = { phrase = "A good book" },
                hello_world = { say = { ["repeat"] = 1, style = "lowercase" } },
            },
        })
    end)

    it("works with the partially-defined configuration", function()
        _assert_good({
            commands = {
                goodnight_moon = {},
                hello_world = {},
            },
        })
    end)
end)

---@diagnostic disable: assign-type-mismatch
---@diagnostic disable: missing-fields
describe("bad configuration - cmdparse", function()
    it("happens with a bad type for #cmdparse.auto_complete.display.help_flag", function()
        _assert_bad({
            cmdparse = { auto_complete = { display = { help_flag = "aaa" } } },
        }, { "cmdparse.auto_complete.display.help_flag: expected boolean, got string" })

        _assert_bad({
            cmdparse = { auto_complete = { display = 123 } },
        }, { "cmdparse.auto_complete.display: expected table, got number" })

        _assert_bad({ cmdparse = { auto_complete = "bnb" } }, { "cmdparse.auto_complete: expected table, got string" })

        _assert_bad({ cmdparse = 123 }, { "cmdparse: expected table, got number" })
    end)

    it("works with an #empty configuration", function()
        _assert_good({
            cmdparse = { auto_complete = { display = { help_flag = true } } },
        })

        _assert_good({
            cmdparse = { auto_complete = { display = { help_flag = false } } },
        })

        _assert_good({
            cmdparse = { auto_complete = { display = { help_flag = nil } } },
        })
    end)
end)

describe("bad configuration - commands", function()
    it("happens with a bad type for #commands.goodnight_moon.phrase", function()
        _assert_bad(
            { commands = { goodnight_moon = { read = { phrase = 10 } } } },
            { "commands.goodnight_moon.read.phrase: expected string, got number" }
        )
    end)

    it("happens with a bad type for #commands.hello_world.say.repeat", function()
        _assert_bad(
            { commands = { hello_world = { say = { ["repeat"] = "foo" } } } },
            { "commands.hello_world.say.repeat: expected a number (value must be 1-or-more), got foo" }
        )
    end)

    it("happens with a bad value for #commands.hello_world.say.repeat", function()
        _assert_bad(
            { commands = { hello_world = { say = { ["repeat"] = -1 } } } },
            { "commands.hello_world.say.repeat: expected a number (value must be 1-or-more), got -1" }
        )
    end)

    it("happens with a bad type for #commands.hello_world.say.style", function()
        _assert_bad(
            { commands = { hello_world = { say = { style = 123 } } } },
            { 'commands.hello_world.say.style: expected "lowercase" or "uppercase", got 123' }
        )
    end)

    it("happens with a bad value for #commands.hello_world.say.style", function()
        _assert_bad(
            { commands = { hello_world = { say = { style = "bad_value" } } } },
            { 'commands.hello_world.say.style: expected "lowercase" or "uppercase", got bad_value' }
        )
    end)
end)
---@diagnostic enable: assign-type-mismatch
---@diagnostic enable: missing-fields

---@diagnostic disable: assign-type-mismatch
describe("bad configuration - logging", function()
    it("happens with a bad value for #logging", function()
        _assert_bad({ logging = false }, { 'logging: expected a table. e.g. { level = "info", ... }, got false' })
    end)

    it("happens with a bad value for #logging.level", function()
        _assert_bad({ logging = { level = false } }, {
            "logging.level: expected an enum. "
                .. 'e.g. "trace" | "debug" | "info" | "warn" | "error" | "fatal", got false',
        })

        _assert_bad({ logging = { level = "does not exist" } }, {
            "logging.level: expected an enum. "
                .. 'e.g. "trace" | "debug" | "info" | "warn" | "error" | "fatal", got does not exist',
        })
    end)

    it("happens with a bad value for #logging.use_console", function()
        _assert_bad({ logging = { use_console = "aaa" } }, { "logging.use_console: expected a boolean, got aaa" })
    end)

    it("happens with a bad value for #logging.use_file", function()
        _assert_bad({ logging = { use_file = "aaa" } }, { "logging.use_file: expected a boolean, got aaa" })
    end)
end)
---@diagnostic enable: assign-type-mismatch

---@diagnostic disable: assign-type-mismatch
describe("health.check", function()
    before_each(function()
        mock_vim.mock_vim_health()
    end)
    after_each(mock_vim.reset_mocked_vim_health)

    it("works with an empty configuration", function()
        health.check({})
        health.check()

        assert.same({}, mock_vim.get_vim_health_errors())
    end)

    it("shows all issues at once", function()
        health.check({
            commands = {
                goodnight_moon = { read = { phrase = 123 } },
                hello_world = { say = { ["repeat"] = "aaa", style = 789 } },
            },
            logging = {
                level = false,
                use_console = "aaa",
                use_file = "fdas",
            },
            tools = {
                lualine = {
                    goodnight_moon = false,
                    hello_world = { text = 456 },
                },
            },
        })

        local found = mock_vim.get_vim_health_errors()
        local issues = tabler.get_slice(found, 1, #found - 1)

        assert.same({
            "commands.goodnight_moon.read.phrase: expected string, got number",
            "commands.hello_world.say.repeat: expected a number (value must be 1-or-more), got aaa",
            'commands.hello_world.say.style: expected "lowercase" or "uppercase", got 789',
            'logging.level: expected an enum. e.g. "trace" | "debug" | "info" | "warn" | "error" | "fatal", got false',
            "logging.use_console: expected a boolean, got aaa",
            "logging.use_file: expected a boolean, got fdas",
            'tools.lualine.goodnight_moon: expected a table. e.g. { text="some text here" }, got false',
        }, issues)

        vim.startswith(found[#found], 'tools.lualine.hello_world.text: expected a string. e.g. "some text here", got ')
    end)
end)
---@diagnostic enable: assign-type-mismatch
