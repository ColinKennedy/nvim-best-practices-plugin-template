--- Make that the Lualine component works as expected.
---
--- @module 'plugin_template.lualine_spec'
---

local api = require("plugin_template.api")
local mock_test = require("test_utilities.mock_test")
local plugin_template = require("lualine.components.plugin_template")
local state = require("plugin_template._core.state")

--- Add the `plugin_template` lualine component (so we can unittest it).
local function _initialize_lualine()
    plugin_template:init({self = {section="y"}})
end

--- Enable lualine so we can create lualine component(s) and other various tasks.
local function _setup_lualine()
    state.PREVIOUS_COMMAND = nil

    mock_test.silence_all_internal_prints()
end

describe("default", function()
    before_each(_setup_lualine)

    it("displays nothing if no command has been run yet", function()
        _initialize_lualine()

        assert.is_nil(plugin_template:update_status())
    end)
end)

describe("API calls", function()
    before_each(_setup_lualine)

    it("works with copy-logs", function()
        _initialize_lualine()

        assert.is_nil(plugin_template:update_status())

        api.run_copy_logs()

        assert.equal(
            "%#lualine_y_plugin_template_copy_logs_inactive#󰈔 Copy Logs",
            plugin_template:update_status()
        )
    end)

    it("works with goodnight-moon count-sheep", function()
        plugin_template:init({self = {section="y"}})

        assert.is_nil(plugin_template:update_status())

        api.run_goodnight_moon_count_sheep(10)

        assert.equal(
            "%#lualine_y_plugin_template_goodnight_moon_inactive# Goodnight moon",
            plugin_template:update_status()
        )
    end)

    it("works with goodnight-moon read", function()
        _initialize_lualine()

        assert.is_nil(plugin_template:update_status())

        api.run_goodnight_moon_read("a book")

        assert.equal(
            "%#lualine_y_plugin_template_goodnight_moon_inactive# Goodnight moon",
            plugin_template:update_status()
        )
    end)

    it("works with goodnight-moon sleep", function()
        _initialize_lualine()

        assert.is_nil(plugin_template:update_status())

        api.run_goodnight_moon_sleep()

        assert.equal(
            "%#lualine_y_plugin_template_goodnight_moon_inactive# Goodnight moon",
            plugin_template:update_status()
        )
    end)

    it("works with hello-world say phrase", function()
        _initialize_lualine()

        assert.is_nil(plugin_template:update_status())

        api.run_hello_world_say_phrase({"A phrase!"})

        assert.equal(
            "%#lualine_y_plugin_template_hello_world_inactive# Hello, World!",
            plugin_template:update_status()
        )
    end)

    it("works with hello-world say word", function()
        _initialize_lualine()

        assert.is_nil(plugin_template:update_status())

        api.run_hello_world_say_word("some_text_here")

        assert.equal(
            "%#lualine_y_plugin_template_hello_world_inactive# Hello, World!",
            plugin_template:update_status()
        )
    end)
end)

describe("Command calls", function()
    before_each(_setup_lualine)

    it("works with copy-logs", function()
        _initialize_lualine()

        assert.is_nil(plugin_template:update_status())

        vim.cmd[[PluginTemplate copy-logs]]

        assert.equal(
            "%#lualine_y_plugin_template_copy_logs_inactive#󰈔 Copy Logs",
            plugin_template:update_status()
        )
    end)

    it("works with goodnight-moon count-sheep", function()
        plugin_template:init({self = {section="y"}})

        assert.is_nil(plugin_template:update_status())

        vim.cmd[[PluginTemplate goodnight-moon count-sheep 10]]

        assert.equal(
            "%#lualine_y_plugin_template_goodnight_moon_inactive# Goodnight moon",
            plugin_template:update_status()
        )
    end)

    it("works with goodnight-moon read", function()
        _initialize_lualine()

        assert.is_nil(plugin_template:update_status())

        vim.cmd[[PluginTemplate goodnight-moon read "a book"]]

        assert.equal(
            "%#lualine_y_plugin_template_goodnight_moon_inactive# Goodnight moon",
            plugin_template:update_status()
        )
    end)

    it("works with goodnight-moon sleep", function()
        _initialize_lualine()

        assert.is_nil(plugin_template:update_status())

        vim.cmd[[PluginTemplate goodnight-moon sleep -zzz]]

        assert.equal(
            "%#lualine_y_plugin_template_goodnight_moon_inactive# Goodnight moon",
            plugin_template:update_status()
        )
    end)

    it("works with hello-world say phrase", function()
        _initialize_lualine()

        assert.is_nil(plugin_template:update_status())

        vim.cmd[[PluginTemplate hello-world say phrase "something more text"]]

        assert.equal(
            "%#lualine_y_plugin_template_hello_world_inactive# Hello, World!",
            plugin_template:update_status()
        )
    end)

    it("works with hello-world say word", function()
        _initialize_lualine()

        assert.is_nil(plugin_template:update_status())

        vim.cmd[[PluginTemplate hello-world say word some_text_here]]

        assert.equal(
            "%#lualine_y_plugin_template_hello_world_inactive# Hello, World!",
            plugin_template:update_status()
        )
    end)
end)
