--- Basic API tests.
---
--- This module is pretty specific to this plugin template so you'll most
--- likely want to delete or heavily modify this file. But it does give a quick
--- look how to mock a test and some things you can do with Neovim/busted.
---
---@module 'plugin_template.plugin_template_spec'
---

local plugin_template = require("plugin_template")

local _DATA = {}
local _ORIGINAL_NOTIFY = vim.notify

--- Keep track of text that would have been printed. Save it to a variable instead.
---
---@param data string Some text to print to stdout.
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

        assert.same({ "-v, -v, -v, -a, -b, -c, -f" }, _DATA)
    end)
end)

-- -- TODO: Fill it out
-- describe("copy-logs API", function()
-- end)
--
-- -- TODO: Fill it out
-- describe("copy-logs commands", function()
--     it("runs #copy-logs with #default arguments", function()
--         vim.cmd([[PluginTemplate copy-logs]])
--     end)
--
--     it("runs #copy-logs with with arguments", function()
--         local path = vim.fn.tempname() .. ".log"
--         vim.cmd(string.format("PluginTemplate copy-logs %s", path))
--     end)
-- end)

describe("hello world API - say phrase/word", function()
    before_each(_initialize_all)
    after_each(_reset_all)

    it("runs #hello-world with default `say phrase` arguments - 001", function()
        plugin_template.run_hello_world_say_phrase({ "" })

        assert.same({ "No phrase was given" }, _DATA)
    end)

    it("runs #hello-world with default `say phrase` arguments - 002", function()
        plugin_template.run_hello_world_say_phrase({})

        assert.same({ "No phrase was given" }, _DATA)
    end)

    it("runs #hello-world with default `say word` arguments - 001", function()
        plugin_template.run_hello_world_say_word("")

        assert.same({ "No word was given" }, _DATA)
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

        assert.same({ "Zzz", "Zzz", "Zzz" }, _DATA)
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
        vim.cmd([[PluginTemplate goodnight-moon sleep -z -z -z]])

        assert.same({ "Zzz", "Zzz", "Zzz" }, _DATA)
    end)
end)


describe("--help flag", function()
    before_each(_initialize_all)
    after_each(_reset_all)

    it("works on the base parser", function()
        vim.cmd([[PluginTemplate --help]])

        assert.same({
[[
Usage: PluginTemplate {arbitrary-thing, copy-logs, goodnight-moon, hello-world} [--help]

Positional Arguments:
    arbitrary-thing    Prepare to sleep or sleep.
    copy-logs    Get debug logs for PluginTemplate.
    goodnight-moon    Prepare to sleep or sleep.
    hello-world    Print hello to the user.

Options:
    --help -h    Show this help message and exit.
]],
        }, _DATA)
    end)

    it("works on a nested subparser - 001", function()
        vim.cmd([[PluginTemplate hello-world say --help]])

        assert.same({
[[
Usage: say {phrase, word} [--help]

Positional Arguments:
    phrase    Print everything that the user types.
    word    Print only the first word that the user types.

Options:
    --help -h    Show this help message and exit.
]],
        }, _DATA)
    end)

    it("works on a nested subparser - 002 #asdf", function()
        vim.cmd([[PluginTemplate hello-world say phrase --help]])

        assert.same({
[[
Usage: phrase phrases [--repeat] [--style] [--help]

Positional Arguments:
   phrases    All of the text to print.

Options:
   --repeat -r    Print to the user X number of times (default=1).
   --style -s    lowercase modifies all capital letters. uppercase modifies all non-capital letter.
   --help -h    Show this help message and exit.
]],
        }, _DATA)
    end)

    it("works on a nested subparser - 003", function()
        vim.cmd([[PluginTemplate hello-world say word --help]])

        assert.same({
[[
Usage: word word [--repeat] [--style] [--help]

Positional Arguments:
   word    The word to print.

Options:
   --repeat -r    Print to the user X number of times (default=1).
   --style -s    lowercase modifies all capital letters. uppercase modifies all non-capital letter.
   --help -h    Show this help message and exit.
]],
        }, _DATA)
    end)

    it("works on the subparsers", function()
        vim.cmd([[PluginTemplate arbitrary-thing --help]])

        assert.same({
[[
Usage: arbitrary-thing [-a] [-b] [-c] [-f] [-v] [--help]

Options:
   -a
   -b
   -c
   -f
   -v
   --help -h    Show this help message and exit.
]],
        }, _DATA)

        vim.cmd([[PluginTemplate copy-logs --help]])

        assert.same({
[[
]],
        }, _DATA)

        vim.cmd([[PluginTemplate goodnight-moon --help]])

        assert.same({
[[
]],
        }, _DATA)

        vim.cmd([[PluginTemplate hello-world --help]])

        assert.same({
[[
]],
        }, _DATA)
    end)
end)
