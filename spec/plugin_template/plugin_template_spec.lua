--- Basic API tests.
---
--- This module is pretty specific to this plugin template so you'll most
--- likely want to delete or heavily modify this file. But it does give a quick
--- look how to mock a test and some things you can do with Neovim/busted.
---
--- @module 'plugin_template.plugin_template_spec'
---

local plugin_template = require("plugin_template")

--- @diagnostic disable: undefined-field

local _DATA = {}
local _ORIGINAL_NOTIFY = vim.notify

--- Keep track of text that would have been printed. Save it to a variable instead.
---
--- @param data string Some text to print to stdout.
---
local function _save_prints(data)
    table.insert(_DATA, data)
end

--- Mock all functions / states before a unittest runs (call this before each test).
local function _initialize_all()
    vim.notify = _save_prints
end

--- Reset all functions / states to their previous settings before the test had run.
local function _reset_all()
    vim.notify = _ORIGINAL_NOTIFY
    _DATA = {}
end

-- describe("arbitrary-thing API", function()
--     before_each(_initialize_all)
--     after_each(_reset_all)
--
--     it("runs #arbitrary-thing with default arguments - 001 #asdf", function()
--         plugin_template.run_arbitrary_thing()
--     end)
-- end)

describe("arbitrary-thing API", function()
    before_each(_initialize_all)
    after_each(_reset_all)

    it("runs #arbitrary-thing with #default arguments", function()
        plugin_template.run_arbitrary_thing({})

        assert.same({ "<No text given>" }, _DATA)
    end)

    it("runs #arbitrary-thing with arguments", function()
        plugin_template.run_arbitrary_thing({ "v", "t" })

        assert.same({ "v, t" }, _DATA)
    end)
end)

describe("arbitrary-thing commands", function()
    before_each(_initialize_all)
    after_each(_reset_all)

    it("runs #arbitrary-thing with #default arguments", function()
        vim.cmd([[PluginTemplate arbitrary-thing]])
        assert.same({ "<No text given>" }, _DATA)
    end)

    it("runs #arbitrary-thing with arguments", function()
        vim.cmd([[PluginTemplate arbitrary-thing -vvv -abc -f]])

        assert.same({ "v, v, v, a, b, c, f" }, _DATA)
    end)
end)

describe("hello world API - say phrase/word", function()
    before_each(_initialize_all)
    after_each(_reset_all)

    it("runs #hello-world with default arguments - 001", function()
        plugin_template.run_hello_world_say_phrase({ "" })

        assert.same({ "No phrase was given" }, _DATA)
    end)

    it("runs #hello-world with default arguments - 002", function()
        plugin_template.run_hello_world_say_phrase({})

        assert.same({ "No phrase was given" }, _DATA)
    end)

    it("runs #hello-world say phrase - with all of its arguments", function()
        plugin_template.run_hello_world_say_phrase({ "Hello,", "World!" }, 2, "lowercase")

        assert.same({ "Saying phrase", "hello, world!", "hello, world!" }, _DATA)
    end)

    it("runs #hello-world say word - with all of its arguments", function()
        plugin_template.run_hello_world_say_phrase({ "Hi" }, 2, "uppercase")

        assert.same({ "Saying phrase", "HI", "HI" }, _DATA)
    end)
end)

describe("hello world commands - say phrase/word", function()
    before_each(_initialize_all)
    after_each(_reset_all)

    it("runs #hello-world with default arguments", function()
        vim.cmd([[PluginTemplate hello-world say phrase]])

        assert.same({ "No phrase was given" }, _DATA)
    end)

    it("runs #hello-world say phrase - with all of its arguments", function()
        vim.cmd([[PluginTemplate hello-world say phrase "Hello, World!" --repeat=2 --style=lowercase]])

        assert.same({ "Saying phrase", "hello, world!", "hello, world!" }, _DATA)
    end)

    it("runs #hello-world say word - with all of its arguments", function()
        vim.cmd([[PluginTemplate hello-world say word "Hi" --repeat=2 --style=uppercase]])

        assert.same({ "Saying word", "HI", "HI" }, _DATA)
    end)
end)

describe("goodnight-moon API", function()
    before_each(_initialize_all)
    after_each(_reset_all)

    it("runs #goodnight-moon #count-sheep with all of its arguments", function()
        plugin_template.run_goodnight_moon_count_sheep(3)

        assert.same({ "1 Sheep", "2 Sheep", "3 Sheep" }, _DATA)
    end)

    it("runs #goodnight-moon #read with all of its arguments", function()
        plugin_template.run_goodnight_moon_read("a good book")

        assert.same({ "a good book: it is a book" }, _DATA)
    end)

    it("runs #goodnight-moon #sleep with all of its arguments", function()
        plugin_template.run_goodnight_moon_sleep(3)

        assert.same({ "zzz", "zzz", "zzz" }, _DATA)
    end)
end)

describe("goodnight-moon commands", function()
    before_each(_initialize_all)
    after_each(_reset_all)

    it("runs #goodnight-moon #count-sheep with all of its arguments", function()
        vim.cmd([[PluginTemplate goodnight-moon count-sheep 3]])

        assert.same({ "1 Sheep", "2 Sheep", "3 Sheep" }, _DATA)
    end)

    it("runs #goodnight-moon #read with all of its arguments", function()
        vim.cmd([[PluginTemplate goodnight-moon read "a good book"]])

        assert.same({ "a good book: it is a book" }, _DATA)
    end)

    it("runs #goodnight-moon #sleep with all of its arguments", function()
        vim.cmd([[PluginTemplate goodnight-moon sleep -zzz]])

        assert.same({ "zzz", "zzz", "zzz" }, _DATA)
    end)
end)
