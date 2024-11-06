--- A custom output handler for [busted](https://github.com/lunarmodules/busted).
---
--- It profile's the user's Neovim plugin and outputs that information to-disk.
---
--- @module 'busted.profile'
---

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

local _FILE_CACHE = {}
local _TEST_CACHE = {}


--- Gather all test profile statistics.
---
---@param element busted.Element The `describe` / `it` / etc that just completed.
---@param parent busted.Element The `describe` block that includes `element`.
---@return string # The found test name (of all `describe` + `it` blocks).
---
local function _get_full_test_name(element, parent)
    local prefix = ""

    if parent.descriptor == "describe" then
        prefix = parent.name .. " - "
    end

    return prefix .. element.name
end

--- Close the profile results on a test that is ending.
---
---@param element busted.Element The `describe` / `it` / etc that just completed.
---@param parent busted.Element The `describe` block that includes `element`.
---
local function _handle_test_end(element, parent)
    local name = _get_full_test_name(element, parent)
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

--- Create an output handler (that records profiling data and outputs it afterwards).
---
---@param options busted.CallerOptions The user-provided terminal statistics.
---@return busted.Handler # The generated handler.
---
return function(options)
    local busted = require('busted')
    local handler = require('busted.outputHandlers.base')()

    profile.start("*")

    ---@param file busted.Element The starting file.
    handler.fileStart = function(file)
        _FILE_CACHE[file.name] = clock()
    end

    ---@param file busted.Element The starting file.
    handler.fileEnd = function(file)
        local start = _FILE_CACHE[file.name]
        local duration = clock() - start

        instrument.add_event(
            {
                name=file.name,
                args = {},
                cat = "file",
                ph = "X",
                ts = start,
                dur = duration,
            }
        )

        _FILE_CACHE[file.name] = nil
    end

    --- Output the profile logs after unittesting ends.
    ---
    ---@param suite busted.Element The top-most object that runs the unittests.
    ---@param count number A 1-or-more value indicating the current test iteration.
    ---@param total number A 1-or-more value - the maximum times that tests can run.
    ---
    handler.suiteEnd = function(suite, count, total)
        if count == total then
            -- TODO: Replace with a real path. later
            profile.export("/mnt/c/Users/korinkite/temp/profile3.json")
            -- profile.export("/mnt/c/Users/korinkite/temp/profile3.json")
        end
    end

    ---@param element busted.Element The `describe` / `it` / etc that just completed.
    ---@param parent busted.Element The `describe` block that includes `element`.
    handler.testStart = function(element, parent)
        _TEST_CACHE[_get_full_test_name(element, parent)] = clock()
    end

    ---@param element busted.Element The `describe` / `it` / etc that just completed.
    ---@param parent busted.Element The `describe` block that includes `element`.
    handler.testEnd = function(element, parent)
        _handle_test_end(element, parent)
    end

    ---@param element busted.Element The `describe` / `it` / etc that just completed.
    ---@param parent busted.Element The `describe` block that includes `element`.
    handler.testFailure = function(element, parent)
        _handle_test_end(element, parent)
    end

    ---@param element busted.Element The `describe` / `it` / etc that just completed.
    ---@param parent busted.Element The `describe` block that includes `element`.
    handler.testError = function(element, parent)
        _handle_test_end(element, parent)
    end

    ---@param element busted.Element The `describe` / `it` / etc that just completed.
    ---@param parent busted.Element The `describe` block that includes `element`.
    handler.error = function(element, parent)
        if element.descriptor == "test" then
            _handle_test_end(element, parent)

            return
        end
    end

    busted.subscribe({ "suite", "reset" }, handler.baseSuiteReset)
    busted.subscribe({ "suite", "end" }, handler.suiteEnd)
    busted.subscribe({ "file", "start" }, handler.fileStart)
    busted.subscribe({ "file", "end" }, handler.fileEnd)
    busted.subscribe({ "test", "start" }, handler.testStart, { predicate = handler.cancelOnPending })
    busted.subscribe({ "test", "end" }, handler.testEnd, { predicate = handler.cancelOnPending })
    busted.subscribe({ "failure", "it" }, handler.testFailure)
    busted.subscribe({ "error", "it" }, handler.testError)
    busted.subscribe({ "failure" }, handler.error)
    busted.subscribe({ "error" }, handler.error)

    return handler
end
