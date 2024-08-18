--- Make sure configuration health checks succeed or fail where they should.
---
--- @module 'plugin_name.configuration_spec'
---

local configuration_ = require("plugin_name._core.configuration")
local health = require("plugin_name.health")

local mock_vim = require("mock_vim")

--- Make sure `data`, whether undefined, defined, or partially defined, is broken.
---
--- @param data PluginNameConfiguration? The user customizations, if any.
--- @param messages string[] All found, expected error messages.
---
local function _assert_bad(data, messages)
    data = configuration_.resolve_data(data)
    local issues = health.get_issues(data)

    if vim.tbl_isempty(issues) then
        error(
            string.format(
                'Test did not fail. Configuration "%s is valid.',
                vim.inspect(data)
            )
        )

        return
    end

    assert.same(messages, issues)
end

--- Make sure `data`, whether undefined, defined, or partially defined, works.
---
--- @param data PluginNameConfiguration? The user customizations, if any.
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
    it("works with an empty configuration", function()
        _assert_good({})
        _assert_good()
    end)

    it("works with a fully defined, custom configuration", function()
        _assert_good(
            {
                commands = {
                  goodnight_moon = { read = {phrase = "The Origin of Consciousness in the Breakdown of the Bicameral Mind" } },
                  hello_world = { say = {["repeat"] = 12, style = "uppercase"} },
                }
            }
        )
    end)

    it("works with the default configuration", function()
        _assert_good(
            {
                commands = {
                  goodnight_moon = { phrase = "A good book" },
                  hello_world = { say = {["repeat"] = 1, style = "lowercase"} },
                }
            }
        )
    end)

    it("works with the partially-defined configuration", function()
        _assert_good(
            {
                commands = {
                  goodnight_moon = { },
                  hello_world = { },
                }
            }
        )
    end)
end)

describe("bad configuration", function()
    it("happens with a bad type for commands.goodnight_moon.phrase", function()
        _assert_bad(
            { commands = { goodnight_moon = { read = { phrase = 10 } } } },
            {"commands.goodnight_moon.read.phrase: expected string, got number (10)"}
        )
    end)

    it("happens with a bad type for commands.hello_world.say.repeat", function()
        _assert_bad(
            { commands = { hello_world = { say = { ["repeat"]  = "foo"} } } },
            {"commands.hello_world.say.repeat: expected a number (value must be 1-or-more), got foo"}
        )
    end)

    it("happens with a bad value for commands.hello_world.say.repeat", function()
        _assert_bad(
            { commands = { hello_world = { say = { ["repeat"] = -1} } } },
            {"commands.hello_world.say.repeat: expected a number (value must be 1-or-more), got -1"}
        )
    end)

    it("happens with a bad type for commands.hello_world.say.style", function()
        _assert_bad(
            { commands = { hello_world = { say = { style = 123} } } },
            {'commands.hello_world.say.style: expected "lowercase" or "uppercase", got 123'}
        )
    end)

    it("happens with a bad value for commands.hello_world.say.style", function()
        _assert_bad(
            { commands = { hello_world = { say = { style = "bad_value"} } } },
            {'commands.hello_world.say.style: expected "lowercase" or "uppercase", got bad_value'}
        )
    end)
end)

describe("health.check", function()
    before_each(mock_vim.mock_vim_health)
    after_each(mock_vim.reset_mocked_vim_health)

    it("works with an empty configuration", function()
        health.check({})
        health.check()

        assert.same({}, mock_vim.get_vim_health())
    end)

    it("shows all issues at once", function()
        health.check(
            {
                commands = {
                    goodnight_moon = { read = {phrase = 123 }},
                    hello_world = { say = {["repeat"] = "asdf", style = 123} },
                }
            }
        )
        local found = mock_vim.get_vim_health()

        assert.same(
            {
                "commands.goodnight_moon.read.phrase: expected string, got number (123)",
                "commands.hello_world.say.repeat: expected a number (value must be 1-or-more), got asdf",
                'commands.hello_world.say.style: expected "lowercase" or "uppercase", got 123',
            },
            found
        )
    end)
end)
