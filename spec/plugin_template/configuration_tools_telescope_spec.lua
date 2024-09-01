--- Make sure configuration health checks for lua succeed or fail where they should.
---
---@module 'plugin_template.configuration_tools_telescope_spec'
---

local configuration_ = require("plugin_template._core.configuration")
local health = require("plugin_template.health")

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

describe("bad configuration - #tools.telescope", function()
    it("happens with a bad type for #tools.telescope", function()
        _assert_bad(
            { tools = { telescope = true } },
            { "tools.telescope: expected a table. e.g. { goodnight_moon = {...}, hello_world = {...}}, got true" }
        )
    end)

    it("happens with a bad type for #tools.telescope.goodnight_moon", function()
        _assert_bad(
            { tools = { telescope = { goodnight_moon = true } } },
            { 'tools.telescope.goodnight_moon: expected a table. e.g. { {"Book", "Author"} }, got true' }
        )
    end)

    it("happens with a bad value for #tools.telescope.goodnight_moon", function()
        local data =
            configuration_.resolve_data({ tools = { telescope = { goodnight_moon = { { true, "asdfasd" } } } } })
        local issues = health.get_issues(data)

        assert.is_truthy(
            vim.startswith(
                issues[1],
                "tools.telescope.goodnight_moon: expected a table. " .. 'e.g. { {"Book", "Author"} }, '
            )
        )
    end)

    it("happens with a bad type for #tools.telescope.hello_world", function()
        _assert_bad(
            { tools = { telescope = { hello_world = true } } },
            { 'tools.telescope.hello_world: expected a table. e.g. { "Hello", "Hi", ...} }, got true' }
        )
    end)

    it("happens with a bad value for #tools.telescope.hello_world", function()
        local data = configuration_.resolve_data({ tools = { telescope = { hello_world = { true } } } })
        local issues = health.get_issues(data)

        assert.is_truthy(
            vim.startswith(
                issues[1],
                "tools.telescope.hello_world: expected a table. e.g. " .. '{ "Hello", "Hi", ...} }, '
            )
        )
    end)
end)

describe("good configuration - #tools.telescope", function()
    it("works with a default #tools.telescope", function()
        _assert_good({ tools = { telescope = {} } })
    end)

    it("works with an empty #tools.telescope.goodnight_moon", function()
        _assert_good({ tools = { telescope = { goodnight_moon = {} } } })
    end)

    it("works with a valid #tools.telescope.goodnight_moon", function()
        _assert_good({ tools = { telescope = { goodnight_moon = { { "Foo", "Bar" } } } } })
    end)

    it("works with an empty #tools.telescope.hello_world", function()
        _assert_good({ tools = { telescope = { hello_world = {} } } })
    end)

    it("works with a valid #tools.telescope.hello_world", function()
        _assert_good({ tools = { telescope = { hello_world = { "Foo", "Bar" } } } })
    end)
end)
