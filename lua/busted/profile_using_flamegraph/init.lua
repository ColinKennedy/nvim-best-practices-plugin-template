--- A custom output handler for [busted](https://github.com/lunarmodules/busted).
---
--- It profile's the user's Neovim plugin and outputs that information to-disk.
---
--- @module 'busted.profile_using_flamegraph'
---

---@see https://github.com/hishamhm/busted-htest/blob/master/src/busted/outputHandlers/htest.lua

local clock = require("profile.clock")
local helper = require("busted.profile_using_flamegraph.helper")
local instrument = require("profile.instrument")
local profile = require("profile")

---@class _GnuplotData The data that we need to generate a graph, using gnuplot.
---@field data_getter fun(artifact: _GraphArtifact): number Grab the value to plot on the graph.
---@field data_path string The .dat file used to read x/y values for the graph.
---@field image_path string The output path where the .png graph will be written to.
---@field script_data string Gnuplot requires a script to generate the graph. This is the script's contents.
---@field script_path string The path on-disk where `script_data` is written to.

---@class _GraphArtifact Summary data about a whole suite of profiler data.
---@field hardware _Hardware All computer platform details.
---@field versions _Versions All software / hardware metadata that generated `statistics`.
---@field statistics _Statistics Summary data about a whole suite of profiler data.

---@class _Hardware All computer platform details.
---@field cpu string The name of the CPU that was used when the profiler ran.
---@field platform string The architecture + OS that was used when the profiler ran.

---@class _NeovimFullVersion The output of Neovim's built-in `vim.version()` function.
---@field major number The breaking-change indicator.
---@field minor number The feature indicator.
---@field patch number The bug / fix indicator.

---@class _NeovimSimplifiedVersion A simple major, minor, patch trio.
---@field [1] number The major version.
---@field [2] number The minor version.
---@field [3] number The patch version.

---@class _ProfileEvent A single, recorded profile event.
---@field cat string The category of the profiler event. e.g. `"function"`, `"test"`, etc.
---@field dur number The length of CPU time needed to complete the event.
---@field ts number The start CPU time.

---@class _Statistics Summary data about a whole suite of profiler data.
---@field mean number (1 + 2 + 3 + ... n) / count
---@field median number The exact middle value of all profile durations.
---@field standard_deviation number The amount of variation in the duration values.
---@field total number The total number of CPU time recorded over the profile.

---@class _Versions
---    All software / hardware metadata that generated `statistics`.
---@field lua string
---    The Lua version that was included with Neovim.
---@field neovim _NeovimFullVersion
---    The user's Neovim version that was used to make the profile results.
---@field release string
---    The version / release tag. e.g. `"v1.2.3"`.
---@field uv number
---    The libuv version that was included with Neovim.

-- TODO: Add logging in this file / around

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

---@type table<string, number>
local _FILE_CACHE = {}
---@type table<string, number>
local _TEST_CACHE = {}

---@type string[]
local _NAME_STACK = {}

local _P = {}

---@return string # The found test name (of all `describe` + `it` blocks).
function _P.get_current_test_path()
    return vim.fn.join(_NAME_STACK, " ")
end

--- Close the profile results on a test that is ending.
function _P.handle_test_end()
    local name = _P.get_current_test_path()
    local start = _TEST_CACHE[name]
    local duration = clock() - start
    instrument.add_event({
        name = name,
        args = {},
        cat = "test",
        ph = "X",
        ts = start,
        dur = duration,
    })

    _TEST_CACHE[name] = nil
end

--- Stop recording timging events for some unittest `path`
---
---@param path string A relative or absolute path on-disk to some _spec.lua file.
---
function _P.stop_profiling_test_file(path)
    local start = _FILE_CACHE[path]
    local duration = clock() - start

    instrument.add_event({
        name = path,
        args = {},
        cat = "file",
        ph = "X",
        ts = start,
        dur = duration,
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

    local root = options.root
    local release = options.release

    if not root or not release then
        -- TODO: Add logger here
        root, release = helper.parse_input_arguments()
    end

    local is_standalone = not profile.is_recording()

    if is_standalone then
        profile.start("*")
    end

    ---@param describe busted.Element The starting file.
    handler.describeStart = function(describe)
        table.insert(_NAME_STACK, describe.name)
    end

    handler.describeEnd = function()
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

        _P.stop_profiling_test_file(file.name)
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

        if is_standalone then
            helper.write_all_summary_directory(release, profile, vim.fs.joinpath(root, "benchmarks", "all"))
        end
    end

    ---@param element busted.Element The `describe` / `it` / etc that just completed.
    handler.testStart = function(element)
        table.insert(_NAME_STACK, element.name)

        _TEST_CACHE[_P.get_current_test_path()] = clock()
    end

    handler.testEnd = function()
        _P.handle_test_end()

        table.remove(_NAME_STACK)
    end

    handler.testFailure = function()
        _P.handle_test_end()
    end

    handler.testError = function()
        _P.handle_test_end()
    end

    ---@param element busted.Element The `describe` / `it` / etc that just completed.
    handler.error = function(element)
        if element.descriptor == "test" then
            _P.handle_test_end()

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
