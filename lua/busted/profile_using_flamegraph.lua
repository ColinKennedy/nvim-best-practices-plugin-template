--- A custom output handler for [busted](https://github.com/lunarmodules/busted).
---
--- It profile's the user's Neovim plugin and outputs that information to-disk.
---
--- @module 'busted.profile'
---

-- TODO: Docstrings

---@see https://github.com/hishamhm/busted-htest/blob/master/src/busted/outputHandlers/htest.lua

local clock = require("profile.clock")
local instrument = require("profile.instrument")
local profile = require("profile")

---@class busted.CallerOptions

---@class busted.Element
---    Some unit of data used by the busted testing framework. It could be
---    a "describe" block or a "it" block or something else.
---@field descriptor string
---    The type of this specific data. e.g. is it a "describe" block or a "it"
---    block or something else.
---@field name string
---    The actual programmer-provided name of this object.

---@class busted.Handler

---@type table<string, number>
local _FILE_CACHE = {}
---@type table<string, number>
local _TEST_CACHE = {}

---@type string[]
local _NAME_STACK = {}

---@return string # The found test name (of all `describe` + `it` blocks).
local function _get_current_test_path()
    return vim.fn.join(_NAME_STACK, " ")
end

--- Close the profile results on a test that is ending.
local function _handle_test_end()
    local name = _get_current_test_path()
    local start = _TEST_CACHE[name]
    local duration = clock() - start
    instrument.add_event(
        {
            name=name,
            args = {},
            cat = "function",
            ph = "X",
            ts = start,
            dur = duration,
        }
    )

    _TEST_CACHE[name] = nil
end

local function _make_parent_directory(path)
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":p:h"), "p")
end

-- path is relative or absolute
local function _stop_profiling_file(path)
    local start = _FILE_CACHE[path]
    local duration = clock() - start

    instrument.add_event(
        {
            name=path,
            args = {},
            cat = "file",
            ph = "X",
            ts = start,
            dur = duration,
        }
    )

    _FILE_CACHE[path] = nil
end


--- Create an output handler (that records profiling data and outputs it afterwards).
---
---@param options busted.CallerOptions The user-provided terminal statistics.
---@return busted.Handler # The generated handler.
---
return function(options)
    local busted = require('busted')
    local handler = require('busted.outputHandlers.base')()

    local export_path = os.getenv("BUSTED_PROFILER_FLAMEGRAPH_OUTPUT_PATH")

    if not export_path then
        error('Cannot write profile results. $BUSTED_PROFILER_FLAMEGRAPH_OUTPUT_PATH is not defined.')
    end

    profile.start("*")

    ---@param describe busted.Element The starting file.
    handler.describeStart = function(describe)
        table.insert(_NAME_STACK, describe.name)
    end

    ---@param describe busted.Element The starting file.
    handler.describeEnd = function(describe)
        table.remove(_NAME_STACK)
    end

    ---@param file busted.Element The starting file.
    handler.fileStart = function(file)
        table.insert(_NAME_STACK, file.name)

        _FILE_CACHE[file.name] = clock()
    end

    ---@param file busted.Element The starting file.
    handler.fileEnd = function(file)
        table.remove(_NAME_STACK)

        _stop_profiling_file(file.name)
    end

    --- Output the profile logs after unittesting ends.
    ---
    ---@param suite busted.Element The top-most object that runs the unittests.
    ---@param count number A 1-or-more value indicating the current test iteration.
    ---@param total number A 1-or-more value - the maximum times that tests can run.
    ---
    handler.suiteEnd = function(suite, count, total)
        if count ~= total then
            -- NOTE: Testing hasn't completed yet.
            return
        end

        _make_parent_directory(export_path)

        print(string.format('Writing profile output to "%s" path.', export_path))

        profile.export(export_path)
    end

    ---@param element busted.Element The `describe` / `it` / etc that just completed.
    ---@param parent busted.Element The `describe` block that includes `element`.
    handler.testStart = function(element, parent)
        table.insert(_NAME_STACK, element.name)

        _TEST_CACHE[_get_current_test_path()] = clock()
    end

    ---@param element busted.Element The `describe` / `it` / etc that just completed.
    ---@param parent busted.Element The `describe` block that includes `element`.
    handler.testEnd = function(element, parent)
        _handle_test_end()

        table.remove(_NAME_STACK)
    end

    ---@param element busted.Element The `describe` / `it` / etc that just completed.
    ---@param parent busted.Element The `describe` block that includes `element`.
    handler.testFailure = function(element, parent)
        _handle_test_end()
    end

    ---@param element busted.Element The `describe` / `it` / etc that just completed.
    ---@param parent busted.Element The `describe` block that includes `element`.
    handler.testError = function(element, parent)
        _handle_test_end()
    end

    ---@param element busted.Element The `describe` / `it` / etc that just completed.
    ---@param parent busted.Element The `describe` block that includes `element`.
    handler.error = function(element, parent)
        if element.descriptor == "test" then
            _handle_test_end()

            return
        end
    end

    busted.subscribe({ "describe", "end" }, handler.describeEnd)
    busted.subscribe({ "describe", "start" }, handler.describeStart)
    busted.subscribe({ "error" }, handler.error)
    busted.subscribe({ "error", "it" }, handler.testError)
    busted.subscribe({ "failure" }, handler.error)
    busted.subscribe({ "failure", "it" }, handler.testFailure)
    busted.subscribe({ "file", "end" }, handler.fileEnd)
    busted.subscribe({ "file", "start" }, handler.fileStart)
    busted.subscribe({ "suite", "end" }, handler.suiteEnd)
    busted.subscribe({ "suite", "reset" }, handler.baseSuiteReset)
    busted.subscribe({ "test", "end" }, handler.testEnd, { predicate = handler.cancelOnPending })
    busted.subscribe({ "test", "start" }, handler.testStart, { predicate = handler.cancelOnPending })

    return handler
end
