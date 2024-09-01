--- Make sure configuration health checks for lua succeed or fail where they should.
---
---@module 'plugin_template.configuration_tools_lualine_spec'
---

local configuration_ = require("plugin_template._core.configuration")
local health = require("plugin_template.health")

---@diagnostic disable: assign-type-mismatch

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

describe("bad configuration - tools.lualine", function()
    it("happens with a bad value for #tools.lualine.goodnight_moon", function()
        _assert_bad(
            { tools = { lualine = { goodnight_moon = true } } },
            { 'tools.lualine.goodnight_moon: expected a table. e.g. { text="some text here" }, got true' }
        )
    end)

    it("happens with a bad value for #tools.lualine.goodnight_moon.color", function()
        local data = configuration_.resolve_data({ tools = { lualine = { goodnight_moon = { color = false } } } })
        local issues = health.get_issues(data)

        assert.equal(1, #issues)

        assert.is_truthy(
            vim.startswith(
                issues[1],
                "tools.lualine.goodnight_moon.color: expected a table. "
                    .. 'e.g. {fg="#000000", bg="#FFFFFF", gui="effect"}'
            )
        )
    end)

    it("happens with a bad value for #tools.lualine.goodnight_moon.color - 002", function()
        local data =
            configuration_.resolve_data({ tools = { lualine = { goodnight_moon = { color = { bg = false } } } } })
        local issues = health.get_issues(data)

        assert.equal(1, #issues)

        assert.is_truthy(
            vim.startswith(
                issues[1],
                "tools.lualine.goodnight_moon.color: expected a table. "
                    .. 'e.g. {fg="#000000", bg="#FFFFFF", gui="effect"}'
            )
        )
    end)

    it("happens with a bad value for #tools.lualine.goodnight_moon.color - 003", function()
        local data =
            configuration_.resolve_data({ tools = { lualine = { goodnight_moon = { color = { fg = false } } } } })
        local issues = health.get_issues(data)

        assert.equal(1, #issues)

        assert.is_truthy(
            vim.startswith(
                issues[1],
                "tools.lualine.goodnight_moon.color: expected a table. "
                    .. 'e.g. {fg="#000000", bg="#FFFFFF", gui="effect"}'
            )
        )
    end)

    it("happens with a bad value for #tools.lualine.goodnight_moon.color - 004", function()
        local data =
            configuration_.resolve_data({ tools = { lualine = { goodnight_moon = { color = { gui = false } } } } })
        local issues = health.get_issues(data)

        assert.equal(1, #issues)

        assert.is_truthy(
            vim.startswith(
                issues[1],
                "tools.lualine.goodnight_moon.color: expected a table. "
                    .. 'e.g. {fg="#000000", bg="#FFFFFF", gui="effect"}'
            )
        )
    end)

    it("happens with a bad value for #tools.lualine.goodnight_moon.color - 005", function()
        local data =
            configuration_.resolve_data({ tools = { lualine = { goodnight_moon = { color = { bad_key = "ttt" } } } } })
        local issues = health.get_issues(data)

        assert.equal(1, #issues)

        assert.is_truthy(
            vim.startswith(
                issues[1],
                "tools.lualine.goodnight_moon.color: expected a table. "
                    .. 'e.g. {fg="#000000", bg="#FFFFFF", gui="effect"}'
            )
        )
    end)

    it("happens with a bad value for #tools.lualine.goodnight_moon.text", function()
        local data = configuration_.resolve_data({ tools = { lualine = { goodnight_moon = { text = false } } } })
        local issues = health.get_issues(data)

        assert.equal(1, #issues)

        assert.is_truthy(
            vim.startswith(
                issues[1],
                'tools.lualine.goodnight_moon.text: expected a string. e.g. "some text here", got '
            )
        )
    end)

    it("happens with a bad value for #tools.lualine.hello_world", function()
        _assert_bad(
            { tools = { lualine = { hello_world = true } } },
            { 'tools.lualine.hello_world: expected a table. e.g. { text="some text here" }, got true' }
        )
    end)

    it("happens with a bad value for #tools.lualine.hello_world.color - 001", function()
        local data = configuration_.resolve_data({ tools = { lualine = { hello_world = { color = false } } } })
        local issues = health.get_issues(data)

        assert.equal(1, #issues)

        assert.is_truthy(
            vim.startswith(
                issues[1],
                "tools.lualine.hello_world.color: expected a table. "
                    .. 'e.g. {fg="#000000", bg="#FFFFFF", gui="effect"}'
            )
        )
    end)

    it("happens with a bad value for #tools.lualine.hello_world.color - 002", function()
        local data = configuration_.resolve_data({ tools = { lualine = { hello_world = { color = { bg = false } } } } })
        local issues = health.get_issues(data)

        assert.equal(1, #issues)

        assert.is_truthy(
            vim.startswith(
                issues[1],
                "tools.lualine.hello_world.color: expected a table. "
                    .. 'e.g. {fg="#000000", bg="#FFFFFF", gui="effect"}'
            )
        )
    end)

    it("happens with a bad value for #tools.lualine.hello_world.color - 003", function()
        local data = configuration_.resolve_data({ tools = { lualine = { hello_world = { color = { fg = false } } } } })
        local issues = health.get_issues(data)

        assert.equal(1, #issues)

        assert.is_truthy(
            vim.startswith(
                issues[1],
                "tools.lualine.hello_world.color: expected a table. "
                    .. 'e.g. {fg="#000000", bg="#FFFFFF", gui="effect"}'
            )
        )
    end)

    it("happens with a bad value for #tools.lualine.hello_world.color - 004", function()
        local data =
            configuration_.resolve_data({ tools = { lualine = { hello_world = { color = { gui = false } } } } })
        local issues = health.get_issues(data)

        assert.equal(1, #issues)

        assert.is_truthy(
            vim.startswith(
                issues[1],
                "tools.lualine.hello_world.color: expected a table. "
                    .. 'e.g. {fg="#000000", bg="#FFFFFF", gui="effect"}'
            )
        )
    end)

    it("happens with a bad value for #tools.lualine.hello_world.color - 005", function()
        local data =
            configuration_.resolve_data({ tools = { lualine = { hello_world = { color = { bad_key = "bbb" } } } } })
        local issues = health.get_issues(data)

        assert.equal(1, #issues)

        assert.is_truthy(
            vim.startswith(
                issues[1],
                "tools.lualine.hello_world.color: expected a table. "
                    .. 'e.g. {fg="#000000", bg="#FFFFFF", gui="effect"}'
            )
        )
    end)

    it("happens with a bad value for #tools.lualine.hello_world.text", function()
        local data = configuration_.resolve_data({ tools = { lualine = { hello_world = { text = false } } } })
        local issues = health.get_issues(data)

        assert.equal(1, #issues)

        assert.is_truthy(
            vim.startswith(
                issues[1],
                "tools.lualine.hello_world.text: " .. 'expected a string. e.g. "some text here", got '
            )
        )
    end)

    it("happens with a bad value for #tools.lualine", function()
        _assert_bad(
            { tools = { lualine = false } },
            { "tools.lualine: expected a table. e.g. { goodnight_moon = {...}, hello_world = {...} }, got false" }
        )
    end)
end)

describe("good configuration - tools.lualine", function()
    it("example good values", function()
        _assert_good({
            tools = {
                lualine = {
                    goodnight_moon = { text = "ttt" },
                    hello_world = { text = "yyyy" },
                },
            },
        })
    end)

    it("happens with a bad value for #tools.lualine.goodnight_moon.color", function()
        local data = configuration_.resolve_data({ tools = { lualine = { goodnight_moon = { color = false } } } })
        local issues = health.get_issues(data)

        assert.equal(1, #issues)

        assert.is_truthy(
            vim.startswith(
                issues[1],
                "tools.lualine.goodnight_moon.color: expected a table. "
                    .. 'e.g. {fg="#000000", bg="#FFFFFF", gui="effect"}'
            )
        )
    end)

    it("happens with a bad value for #tools.lualine.goodnight_moon.text", function()
        local data = configuration_.resolve_data({ tools = { lualine = { goodnight_moon = { text = false } } } })
        local issues = health.get_issues(data)

        assert.equal(1, #issues)

        assert.is_truthy(
            vim.startswith(
                issues[1],
                'tools.lualine.goodnight_moon.text: expected a string. e.g. "some text here", got '
            )
        )
    end)

    it("happens with a bad value for #tools.lualine.hello_world", function()
        _assert_bad(
            { tools = { lualine = { hello_world = true } } },
            { 'tools.lualine.hello_world: expected a table. e.g. { text="some text here" }, got true' }
        )
    end)

    it("happens with a bad value for #tools.lualine.hello_world.color", function()
        local data = configuration_.resolve_data({ tools = { lualine = { hello_world = { color = false } } } })
        local issues = health.get_issues(data)

        assert.equal(1, #issues)

        assert.is_truthy(
            vim.startswith(
                issues[1],
                "tools.lualine.hello_world.color: expected a table. "
                    .. 'e.g. {fg="#000000", bg="#FFFFFF", gui="effect"}'
            )
        )
    end)

    it("happens with a bad value for #tools.lualine.hello_world.text", function()
        local data = configuration_.resolve_data({ tools = { lualine = { hello_world = { text = false } } } })
        local issues = health.get_issues(data)

        assert.equal(1, #issues)

        assert.is_truthy(
            vim.startswith(
                issues[1],
                "tools.lualine.hello_world.text: " .. 'expected a string. e.g. "some text here", got '
            )
        )
    end)

    it("happens with a bad value for #tools.lualine", function()
        _assert_bad(
            { tools = { lualine = false } },
            { "tools.lualine: expected a table. e.g. { goodnight_moon = {...}, hello_world = {...} }, got false" }
        )
    end)
end)
