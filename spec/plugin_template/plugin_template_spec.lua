--- Basic API tests.
---
--- This module is pretty specific to this plugin template so you'll most
--- likely want to delete or heavily modify this file. But it does give a quick
--- look how to mock a test and some things you can do with Neovim/busted.
---
---@module 'plugin_template.plugin_template_spec'
---

local configuration = require("plugin_template._core.configuration")
local copy_logs_runner = require("plugin_template._commands.copy_logs.runner")
local plugin_template = require("plugin_template")
local vlog = require("plugin_template._vendors.vlog")

---@class plugin_template.Configuration
local _CONFIGURATION_DATA

---@type string[]
local _DATA = {}

local _ORIGINAL_COPY_LOGS_READ_FILE = copy_logs_runner._read_file
local _ORIGINAL_NOTIFY = vim.notify

--- Keep track of text that would have been printed. Save it to a variable instead.
---
---@param data string Some text to print to stdout.
---
local function _save_prints(data)
    table.insert(_DATA, data)
end

--- Mock all functions / states before a unittest runs (call this before each test).
local function _initialize_prints()
    vim.notify = _save_prints
end

--- Watch the `copy-logs` API command for function calls.
local function _initialize_copy_log()
    local function _save_path(path)
        _DATA = { path }
    end

    _CONFIGURATION_DATA = vim.deepcopy(configuration.DATA)
    copy_logs_runner._read_file = _save_path
end

--- Write a log file so we can query its later later.
local function _make_fake_log(path)
    local file = io.open(path, "w") -- Open the file in write mode

    if not file then
        error(string.format('Path "%s" is not writable.', path))
    end

    file:write("aaa\nbbb\nccc\n")
    file:close()
end

--- Remove the "watcher" that we added during unittesting.
local function _reset_copy_log()
    copy_logs_runner._read_file = _ORIGINAL_COPY_LOGS_READ_FILE

    configuration.DATA = _CONFIGURATION_DATA
    _DATA = {}
end

--- Reset all functions / states to their previous settings before the test had run.
local function _reset_prints()
    vim.notify = _ORIGINAL_NOTIFY
    _DATA = {}
end

--- Wait for our (mocked) unittest variable to get some data back.
---
---@param timeout number?
---    The milliseconds to wait before continuing. If the timeout is exceeded
---    then we stop waiting for all of the functions to call.
---
local function _wait_for_result(timeout)
    if timeout == nil then
        timeout = 1000
    end

    vim.wait(timeout, function()
        return not vim.tbl_isempty(_DATA)
    end)
end

describe("arbitrary-thing API", function()
    before_each(_initialize_prints)
    after_each(_reset_prints)

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
    before_each(_initialize_prints)
    after_each(_reset_prints)

    it("runs #arbitrary-thing with #default arguments", function()
        vim.cmd([[PluginTemplate arbitrary-thing]])
        assert.same({ "<No text given>" }, _DATA)
    end)

    it("runs #arbitrary-thing with arguments", function()
        vim.cmd([[PluginTemplate arbitrary-thing -vvv -abc -f]])

        assert.same({ "-v, -v, -v, -a, -b, -c, -f" }, _DATA)
    end)
end)

describe("copy logs API", function()
    before_each(_initialize_copy_log)
    after_each(_reset_copy_log)

    it("runs with an explicit file path", function()
        local path = vim.fn.tempname() .. "copy_logs_test.log"
        _make_fake_log(path)

        plugin_template.run_copy_logs(path)
        _wait_for_result()

        assert.same({ path }, _DATA)
    end)

    it("runs with default arguments", function()
        local expected = vim.fn.tempname() .. "copy_logs_default_test.log"
        configuration.DATA.logging.output_path = expected
        vlog.new(configuration.DATA.logging or {}, true)
        _make_fake_log(expected)

        plugin_template.run_copy_logs()
        _wait_for_result()

        assert.same({ expected }, _DATA)
    end)
end)

describe("copy logs command", function()
    before_each(_initialize_copy_log)
    after_each(_reset_copy_log)

    it("runs with an explicit file path", function()
        local path = vim.fn.tempname() .. "copy_logs_test.log"
        _make_fake_log(path)

        vim.cmd(string.format('PluginTemplate copy-logs "%s"', path))
        _wait_for_result()

        assert.same({ path }, _DATA)
    end)

    it("runs with default arguments", function()
        local expected = vim.fn.tempname() .. "copy_logs_default_test.log"
        configuration.DATA.logging.output_path = expected
        vlog.new(configuration.DATA.logging or {}, true)
        _make_fake_log(expected)

        vim.cmd([[PluginTemplate copy-logs]])

        _wait_for_result()

        assert.same({ expected }, _DATA)
    end)
end)

describe("hello world API - say phrase/word", function()
    before_each(_initialize_prints)
    after_each(_reset_prints)

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
    before_each(_initialize_prints)
    after_each(_reset_prints)

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
    before_each(_initialize_prints)
    after_each(_reset_prints)

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
    before_each(_initialize_prints)
    after_each(_reset_prints)

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

describe("help API", function()
    before_each(_initialize_prints)
    after_each(_reset_prints)

    describe("fallback help", function()
        it("works on a nested subparser - 003", function()
            vim.cmd("PluginTemplate hello-world say")
            assert.same({ "Usage: {say} {phrase,word} [--help]" }, _DATA)
        end)
    end)

    describe("--help flag", function()
        it("works on the base parser", function()
            vim.cmd("PluginTemplate --help")

            assert.same({
                [[
Usage: {PluginTemplate} {arbitrary-thing,copy-logs,goodnight-moon,hello-world} [--help]

Commands:
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
Usage: {say} {phrase,word} [--help]

Commands:
    phrase    Print everything that the user types.
    word    Print only the first word that the user types.

Options:
    --help -h    Show this help message and exit.
]],
            }, _DATA)
        end)

        it("works on a nested subparser - 002", function()
            vim.cmd([[PluginTemplate hello-world say phrase --help]])

            assert.same({
                [[
Usage: {phrase} PHRASES* [--repeat {1,2,3,4,5}] [--style {lowercase,uppercase}] [--help]

Positional Arguments:
    PHRASES*    All of the text to print.

Options:
    --repeat -r {1,2,3,4,5}    Print to the user X number of times (default=1).
    --style -s {lowercase,uppercase}    lowercase makes WORD into word. uppercase does the reverse.
    --help -h    Show this help message and exit.
]],
            }, _DATA)
        end)

        it("works on a nested subparser - 003", function()
            vim.cmd([[PluginTemplate hello-world say word --help]])

            assert.same({
                [[
Usage: {word} WORD [--repeat {1,2,3,4,5}] [--style {lowercase,uppercase}] [--help]

Positional Arguments:
    WORD    The word to print.

Options:
    --repeat -r {1,2,3,4,5}    Print to the user X number of times (default=1).
    --style -s {lowercase,uppercase}    lowercase makes WORD into word. uppercase does the reverse.
    --help -h    Show this help message and exit.
]],
            }, _DATA)
        end)

        it("works on the subparsers - 001", function()
            vim.cmd([[PluginTemplate arbitrary-thing --help]])

            assert.same({
                [[
Usage: {arbitrary-thing} [-a] [-b] [-c] [-f] [-v] [--help]

Options:
    -a    The -a flag.
    -b    The -b flag.
    -c    The -c flag.
    -f *    The -f flag.
    -v *    The -v flag.
    --help -h    Show this help message and exit.
]],
            }, _DATA)
        end)

        it("works on the subparsers - 002", function()
            vim.cmd([[PluginTemplate copy-logs --help]])

            assert.same({
                [[
Usage: {copy-logs} LOG [--help]

Positional Arguments:
    LOG    The path on-disk to look for logs. If no path is given, a fallback log path is used instead.

Options:
    --help -h    Show this help message and exit.
]],
            }, _DATA)
        end)

        it("works on the subparsers - 003", function()
            vim.cmd([[PluginTemplate goodnight-moon --help]])

            assert.same({
                [[
Usage: {goodnight-moon} {count-sheep,read,sleep} [--help]

Commands:
    count-sheep    Count some sheep to help you sleep.
    read    Read a book in bed.
    sleep    Sleep tight!

Options:
    --help -h    Show this help message and exit.
]],
            }, _DATA)
        end)

        it("works on the subparsers - 004", function()
            vim.cmd([[PluginTemplate hello-world --help]])

            assert.same({
                [[
Usage: {hello-world} {say} [--help]

Commands:
    say    Print something to the user.

Options:
    --help -h    Show this help message and exit.
]],
            }, _DATA)
        end)
    end)
end)
