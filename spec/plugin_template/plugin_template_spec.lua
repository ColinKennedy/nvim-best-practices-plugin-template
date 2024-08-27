--- Basic API tests.
---
--- This module is pretty specific to this plugin template so you'll most
--- likely want to delete or heavily modify this file. But it does give a quick
--- look how to mock a test and some things you can do with Neovim/busted.
---
--- @module 'plugin_template.plugin_template_spec'
---

local api = require("plugin_template.api")
local configuration = require("plugin_template._core.configuration")
local count_sheep_runner = require("plugin_template._commands.goodnight_moon.count_sheep.runner")
local mock_test = require("test_utilities.mock_test")
local read_runner = require("plugin_template._commands.goodnight_moon.read.runner")
local say_runner = require("plugin_template._commands.hello_world.say.runner")
local sleep_runner = require("plugin_template._commands.goodnight_moon.sleep.runner")

--- @diagnostic disable: undefined-field

local _DATA = {}
local _ORIGINAL_COUNT_SHEEP_PRINTER = count_sheep_runner._print
local _ORIGINAL_READ_PRINTER = read_runner._print
local _ORIGINAL_SAY_PRINTER = say_runner._print
local _ORIGINAL_SLEEP_PRINTER = sleep_runner._print

--- Keep track of text that would have been printed. Save it to a variable instead.
---
--- @param data string Some text to print to stdout.
---
local function _save_prints(data)
    table.insert(_DATA, data)
end

describe("hello world api - say phrase/word", function()
    before_each(function()
        say_runner._print = _save_prints
        configuration.initialize_data_if_needed()
    end)

    after_each(function()
        say_runner._print = _ORIGINAL_SAY_PRINTER
        _DATA = {}
    end)

    it("runs hello-world with default arguments - 001", function()
        api.run_hello_world_say_phrase({ "" })

        assert.same({ "No phrase was given" }, _DATA)
    end)

    it("runs hello-world with default arguments - 002", function()
        api.run_hello_world_say_phrase({ })

        assert.same({ "No phrase was given" }, _DATA)
    end)

    it("runs hello-world say phrase - with all of its arguments", function()
        api.run_hello_world_say_phrase({ "Hello,", "World!" }, 2, "lowercase")

        assert.same({ "Saying phrase", "hello, world!", "hello, world!" }, _DATA)
    end)

    it("runs hello-world say word - with all of its arguments", function()
        api.run_hello_world_say_phrase({ "Hi" }, 2, "uppercase")

        assert.same({ "Saying phrase", "HI", "HI" }, _DATA)
    end)
end)

describe("hello world commands - say phrase/word", function()
    before_each(function()
        say_runner._print = _save_prints
        configuration.initialize_data_if_needed()
    end)

    after_each(function()
        say_runner._print = _ORIGINAL_SAY_PRINTER
        _DATA = {}
    end)

    it("runs hello-world with default arguments", function()
        vim.cmd([[PluginTemplate hello-world say phrase]])

        assert.same({ "No phrase was given" }, _DATA)
    end)

    it("runs hello-world say phrase - with all of its arguments", function()
        vim.cmd([[PluginTemplate hello-world say phrase "Hello, World!" --repeat=2 --style=lowercase]])

        assert.same({ "Saying phrase", "hello, world!", "hello, world!" }, _DATA)
    end)

    it("runs hello-world say word - with all of its arguments", function()
        vim.cmd([[PluginTemplate hello-world say word "Hi" --repeat=2 --style=uppercase]])

        assert.same({ "Saying word", "HI", "HI" }, _DATA)
    end)
end)

describe("goodnight-moon api", function()
    before_each(function()
        count_sheep_runner._print = _save_prints
        read_runner._print = _save_prints
        sleep_runner._print = _save_prints
        configuration.initialize_data_if_needed()
    end)

    after_each(function()
        count_sheep_runner._print = _ORIGINAL_COUNT_SHEEP_PRINTER
        read_runner._print = _ORIGINAL_READ_PRINTER
        sleep_runner._print = _ORIGINAL_SLEEP_PRINTER
        _DATA = {}
    end)

    it("runs goodnight-moon count-sheep with all of its arguments", function()
        api.run_goodnight_moon_count_sheep(3)

        assert.same({ "1 Sheep", "2 Sheep", "3 Sheep" }, _DATA)
    end)

    it("runs goodnight-moon read with all of its arguments", function()
        api.run_goodnight_moon_read("a good book")

        assert.same({ "a good book: it is a book" }, _DATA)
    end)

    it("runs goodnight-moon sleep with all of its arguments", function()
        api.run_goodnight_moon_sleep(3)

        assert.same({ "zzz", "zzz", "zzz" }, _DATA)
    end)
end)

describe("goodnight-moon commands", function()
    before_each(function()
        count_sheep_runner._print = _save_prints
        read_runner._print = _save_prints
        sleep_runner._print = _save_prints
        configuration.initialize_data_if_needed()
    end)

    after_each(function()
        count_sheep_runner._print = _ORIGINAL_COUNT_SHEEP_PRINTER
        read_runner._print = _ORIGINAL_READ_PRINTER
        sleep_runner._print = _ORIGINAL_SLEEP_PRINTER
        _DATA = {}
    end)

    it("runs goodnight-moon count-sheep with all of its arguments", function()
        vim.cmd([[PluginTemplate goodnight-moon count-sheep 3]])

        assert.same({ "1 Sheep", "2 Sheep", "3 Sheep" }, _DATA)
    end)

    it("runs goodnight-moon read with all of its arguments", function()
        vim.cmd([[PluginTemplate goodnight-moon read "a good book"]])

        assert.same({ "a good book: it is a book" }, _DATA)
    end)

    it("runs goodnight-moon sleep with all of its arguments", function()
        vim.cmd([[PluginTemplate goodnight-moon sleep -zzz]])

        assert.same({ "zzz", "zzz", "zzz" }, _DATA)
    end)
end)
