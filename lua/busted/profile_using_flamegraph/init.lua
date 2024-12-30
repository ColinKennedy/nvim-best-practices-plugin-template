--- A custom output handler for [busted](https://github.com/lunarmodules/busted).
---
--- It profile's the user's Neovim plugin and outputs that information to-disk.
---
--- @module 'busted.profile_using_flamegraph'
---

---@see https://github.com/hishamhm/busted-htest/blob/master/src/busted/outputHandlers/htest.lua

local clock = require("profile.clock")
local constant = require("busted.profile_using_flamegraph.constant")
local helper = require("busted.profile_using_flamegraph.helper")
local instrument = require("profile.instrument")
local logging = require("mega.logging")
local profile = require("profile")
local util = require("profile.util")

---@class busted.FlamegraphCallerOptions Control how an output handler runs.
---@field release string A version / release tag. e.g. `"v1.2.3"`.
---@field root string An absolute path to the directory on-disk where files are written.

---@class busted.Element
---    Some unit of data used by the busted testing framework. It could be
---    a "describe" block or a "it" block or something else.
---@field descriptor string
---    The type of this specific data. e.g. is it a "describe" block or a "it"
---    block or something else.
---@field name string
---    The actual programmer-provided name of this object.

---@class busted.Handler

local _LOGGER = logging.get_logger("busted.profile_using_flamegraph")

---@type table<string, number>
local _DESCRIBE_CACHE = {}

---@type string[]
local _DESCRIBE_STACK = {}

---@type table<string, number>
local _FILE_CACHE = {}

---@type table<string, number>
local _TEST_CACHE = {}

---@type string[]
local _NAME_STACK = {}

local _CATEGORY_SEPARATOR = ","

local _P = {}

---@return string # The found test name (of all `describe` blocks).
function _P.get_current_describe_path()
    return vim.fn.join(_DESCRIBE_STACK, " ")
end

---@return string # The found test name (of all `describe` + `it` blocks).
function _P.get_current_test_path()
    return vim.fn.join(_NAME_STACK, " ")
end

--- Delete all tests that live within the current test path.
---
--- Important:
---     This function should only be called once per context when you are sure
---     that the tests has completed. Otherwise you might end up deleting
---     timing data before you need it.
---
--- Lua's busted test framework supports nested `describe` blocks. When this
--- function is called, all timing data for the current `describe` block + all
--- of its children are released to keep memory consumption down.
---
function _P.clear_child_tests_cache()
    local current = _P.get_current_test_path()

    for name, _ in pairs(_TEST_CACHE) do
        if vim.startswith(name, current) then
            _TEST_CACHE[name] = nil
        end
    end
end

--- Close the profile results on a test that is ending.
---
---@param categories string The qualifiers to add to this profiler event.
---
function _P.handle_test_end(categories)
    local name = _P.get_current_test_path()
    local start = _TEST_CACHE[name]
    local duration = clock() - start
    instrument.add_event({
        args = {},
        cat = categories,
        dur = duration,
        name = name,
        ph = "X",
        pid = util.get_process_id(),
        tid = util.get_thread_id(),
        ts = start,
    })
end

--- Concatenate all arguments into a comma-separated string.
---
---@param ... string All arguments to join
---@return string # The created string.
---
function _P.make_categories(...)
    return vim.fn.join({...}, _CATEGORY_SEPARATOR)
end

--- Stop recording timging events for some unittest `path`
---
---@param path string A relative or absolute path on-disk to some _spec.lua file.
---
function _P.stop_profiling_test_file(path)
    local start = _FILE_CACHE[path]
    local duration = clock() - start

    instrument.add_event({
        args = {},
        cat = constant.Category.file,
        dur = duration,
        name = path,
        ph = "X",
        pid = util.get_process_id(),
        tid = util.get_thread_id(),
        ts = start,
    })

    _FILE_CACHE[path] = nil
end

--- Create an output handler (that records profiling data and outputs it afterwards).
---
---@param options busted.FlamegraphCallerOptions Control how an output handler runs.
---@return busted.Handler # The generated handler.
---
return function(options)
    local busted = require("busted")
    local handler = require("busted.outputHandlers.base")()

    local environment_options = helper.get_environment_variable_data()
    local root = options.root
    local release = options.release

    if not root or not release then
        _LOGGER:info(
            "Either root or release was not found. " .. "Getting root / release from environment variables instead."
        )
        root = environment_options.root
        release = environment_options.release
    end

    local is_standalone = not profile.is_recording()

    if is_standalone then
        _LOGGER:info("Now capturing all profile logs.")

        profile.start("*")
    end

    ---@param describe busted.Element The starting file.
    handler.describeStart = function(describe)
        table.insert(_NAME_STACK, describe.name)
        table.insert(_DESCRIBE_STACK, describe.name)

        _DESCRIBE_CACHE[_P.get_current_describe_path()] = clock()
    end

    handler.describeEnd = function()
        table.remove(_NAME_STACK)

        local name = _P.get_current_describe_path()
        local start = _DESCRIBE_CACHE[name]
        local duration = clock() - start
        instrument.add_event({
            args = {},
            cat = constant.Category.describe,
            dur = duration,
            name = name,
            ph = "X",
            pid = util.get_process_id(),
            tid = util.get_thread_id(),
            ts = start,
        })

        _DESCRIBE_CACHE[name] = nil

        table.remove(_DESCRIBE_STACK)
    end

    ---@param file busted.Element The starting file.
    handler.fileStart = function(file)
        table.insert(_NAME_STACK, file.name)

        _FILE_CACHE[file.name] = clock()
    end

    ---@param file busted.Element The starting file.
    handler.fileEnd = function(file)
        table.remove(_NAME_STACK)

        _P.clear_child_tests_cache()
        _P.stop_profiling_test_file(file.name)
    end

    --- Output the profile logs after unittesting ends.
    ---
    ---@param _ busted.Element The top-most object that runs the unittests.
    ---@param count number A 1-or-more value indicating the current test iteration.
    ---@param total number A 1-or-more value - the maximum times that tests can run.
    ---
    handler.suiteEnd = function(_, count, total)
        if count ~= total then
            -- NOTE: Testing hasn't completed yet.
            return
        end

        if is_standalone then
            profile.stop()
            _LOGGER:info("Profiling was stopped. Now writing to disk.")
            local benchmarks = vim.fs.joinpath(root, "benchmarks")
            local events = instrument.get_events()
            helper.write_summary_directory(
                profile,
                events,
                nil,
                vim.tbl_deep_extend("force", environment_options, { release = release, root = vim.fs.joinpath(benchmarks, "all") })
            )
            helper.write_tags_directory(
                profile,
                events,
                nil,
                vim.tbl_deep_extend("force", environment_options, { release = release, root = vim.fs.joinpath(benchmarks, "tags") })
            )
        end
    end

    ---@param element busted.Element The `describe` / `it` / etc that just completed.
    handler.testStart = function(element)
        table.insert(_NAME_STACK, element.name)

        local path = _P.get_current_test_path()
        _TEST_CACHE[path] = clock()

        instrument.add_event({
            args = {},
            cat = constant.Category.start,
            dur = -1,
            name = path,
            ph = "X",
            pid = util.get_process_id(),
            tid = util.get_thread_id(),
            ts = clock(),
        })
    end

    handler.testEnd = function()
        _P.handle_test_end(constant.Category.test)

        table.remove(_NAME_STACK)
    end

    handler.testFailure = function()
        _P.handle_test_end(_P.make_categories(constant.Category.test, constant.Category.failure))
    end

    handler.testError = function()
        _P.handle_test_end(_P.make_categories(constant.Category.test, constant.Category.error))
    end

    ---@param element busted.Element The `describe` / `it` / etc that just completed.
    handler.error = function(element)
        if element.descriptor == "test" then
            _P.handle_test_end(_P.make_categories(constant.Category.test, constant.Category.error))

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
