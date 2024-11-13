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

-- TODO: Finish this
---@class _GraphArtifact
---@field release string
---@field total number

-- TODO: Finish
---@class _SummaryTimingLine
---@field mean number
---@field median number
---@field standard_deviation number
---@field total number

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
local _MAXIMUM_ARTIFACTS = 40 -- TODO: Do some tests to figure out what maximum number should be

local _DETAILS_FILE_NAME = "details.json"

local _P = {}

---@return string # The found test name (of all `describe` + `it` blocks).
function _P.get_current_test_path()
    return vim.fn.join(_NAME_STACK, " ")
end

--- Read all past profile / timing results into a single array.
---
--- Raises:
---     If a found results file cannot be read from JSON.
---
---@param root string
---    An absolute path to the direct-parent directory. e.g. `".../benchmarks/all/artifacts".
---@return _GraphArtifact[]
---    All found records so far, if any.
---
function _P.get_graph_artifacts(root)
    ---@type _GraphArtifact[]
    local output = {}

    local template = vim.fs.joinpath(root, "*", _DETAILS_FILE_NAME)

    for _, path in ipairs(vim.fn.glob(template, false, true)) do
        local file = io.open(path, "r")

        if not file then
            error(string.format('Path "%s" could not be opened.', path), 0)
        end

        local data = file:read("*a")

        local success, result = pcall(vim.fn.json_decode, data)

        if not success then
            error(string.format('Path "%s" could not be read as JSON.', path), 0)
        end

        table.insert(output, result)
    end

    return output
end

--- Add graph data to the "benchmarks/all/README.md" file.
---
--- Or create the file if it does not exist.
---
---@param data _SummaryTimingLine Some timing data to append to the README.md's markdown table.
---@param path string The path on-disk to write the README.md to.
---
function _P.append_to_summary_readme(data, path)
    -- TODO: Change the code for the summary README.md - Make it easy for anyone
    -- their own "highlight this specific thing that I want to track" API.
    _P.create_summary_readme_if_needed(path)

    local file = io.open(path, "a")

    if not file then
        error(string.format('Cannot append to "%s" path.', path), 0)
    end

    -- TODO: Find a way to pass in the release, maybe
    local release = "TODO"
    local platform = vim.loop.os_uname().sysname
    -- TODO: To the get CPU
    -- TODO: Maybe vim.uv.cpu_info() but really we should use something better here
    -- https://docs.python.org/3/library/platform.html#platform.processor
    local cpu = "TODO"

    file:write(
        "| %s | %s | %s | %s | %s | %s | %s |",
        release,
        platform,
        cpu,
        data.total,
        data.median,
        data.mean,
        data.standard_deviation
    )
end

--- Make the "benchmarks/all/README.md" file if it doesn't exist already.
---
--- Raises:
---     If `path` is not writeable.
---
---@param path string The absolute path on-disk to write the file.
---
function _P.create_summary_readme_if_needed(path)
    if vim.fn.filereadable(path) == 1 then
        return
    end

    _P.make_parent_directory(path)

    local file = io.open(path, "w")

    if not file then
        error(string.format('Path "%s" could not be created.', path))
    end

    file:write([[
        # Benchmarking Results

        This document contains historical benchmarking results. These measure the speed
        of resolution of a list of predetermined requests. Do **NOT** change this file
        by hand; the Github workflows will do this automatically.

        <p align="center"><img src="solvetimes.png" /></p>

        | Release | Platform | CPU | Total | Median | Mean | StdDev |
        |---------|----------|-----|-------|--------|------|--------|
        ]])
    file:close()
end

--- Close the profile results on a test that is ending.
function _P.handle_test_end()
    local name = _P.get_current_test_path()
    local start = _TEST_CACHE[name]
    local duration = clock() - start
    instrument.add_event({
        name = name,
        args = {},
        cat = "function",
        ph = "X",
        ts = start,
        dur = duration,
    })

    _TEST_CACHE[name] = nil
end

--- Create a line-graph at `path` using `artifacts`.
---
---@param artifacts _GraphArtifact[]
---    All past profiling / timing records to make a graph.
---@param path string
---    An absolute path on-disk to write this graph to.
---
function _P.make_graph(artifacts, path)
    -- TODO: Finish
end

--- Create the parent directory that will contain `path`.
---
---@param path string
---    An absolute path to a file / symlink. It's expected that `path` does not
---    already exist on disk and probably neither does its parent directory.
---
function _P.make_parent_directory(path)
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":p:h"), "p")
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

-- TODO: Make sure this file structure works
--- Write all files for the "benchmarks/all" directory.
---
--- The basic directory structure looks like this:
---
--- - all/
---     - artifacts/
---         - {YYYY_MM_DD-VERSION_TAG}/
---             - Contains their own README.md + details.json
---             - profile.json
---             - flamegraph.json
---     - README.md
---         - Show the graph of the output, across versions
---         - A table summary of the timing
---     - flamegraph.json
---     - profile.json - The latest release's total time, self time, etc
---     - timing.png - A line-graph of tests over-time.
---
---@param root string The ".../benchmarks/all" directory to create or update.
---
function _P.write_all_summary_directory(root)
    -- TODO: Change this code to generate the {YYYY_MM_DD-VERSION_TAG}/
    -- directory first and then just copy its flamegraph.json and profile.json
    -- to the all/ root directory.
    _P.write_flamegraph(vim.fs.joinpath(root, "flamegraph.json"), profile)
    local profile_data = _P.write_profile_summary(vim.fs.joinpath(root, "profile.json"))
    _P.append_to_summary_readme(profile_data, vim.fs.joinpath(root, "README.md"))
    -- TODO: Find a way to pass in the release, maybe
    local release = "TODO"
    _P.write_graph_artifact(release, root)
    _P.make_graph(_P.get_graph_artifacts(root, _MAXIMUM_ARTIFACTS), vim.fs.joinpath(root, "timing.png"))
end

-- TODO: Docstring
-- Do I even still need this directory anymore? Probably but just checking
function _P.write_by_release_directory(root) end

--- Export `profile` to `path` as a new profiler flamegraph.
---
---@param profiler Profiler The object used to record function call times.
---@param path string An absolute path to a flamegraph.json to create.
---
function _P.write_flamegraph(profiler, path)
    _P.make_parent_directory(path)

    profiler.export(path)
end

--- Create the `"benchmarks/all/artifacts/{YYYY_MM_DD-VERSION_TAG}"` directory.
---
---@param release string The current release to make.
---@param root string The ".../benchmarks/all" directory to create or update.
---
function _P.write_graph_artifact(release, root)
    local current_date_time = os.date("%Y_%m_%d-%H_%M_%S")
    local path = vim.fs.joinpath(root, string.format("%s-%s", current_date_time, release, _DETAILS_FILE_NAME))

    _P.make_parent_directory(path)
end

-- TODO: Maybe rename this file to "summary.json"?
--- Create a profile.json file to summarize the final results of the profiler.
---
--- Raises:
---     If `path` is not writable or fails to write.
---
---@param path string An absolute path to the ".../benchmarks/all/profile.json" to create.
---
function _P.write_profile_summary(path)
    _P.make_parent_directory(path)

    local file = io.open(path, "w")

    if not file then
        error(string.format('Path "%s" could not be exported.', path), 0)
    end

    ---@type _SummaryTimingLine
    local data = {
        -- TODO: Finish these values somehow
        mean = 1.23,
        median = 1.23,
        standard_deviation = 1.23,
        total = 1.23,
    }

    -- TODO: Add data here. Look at Rez as an example
    -- for _,
    -- print("WRITE THE SUMMARY")
    -- instrument.get_events()

    file:write(vim.fn.json_encode(data))
    file:close()

    return data
end

--- Create an output handler (that records profiling data and outputs it afterwards).
---
---@param options busted.CallerOptions The user-provided terminal statistics.
---@return busted.Handler # The generated handler.
---
return function(options)
    local busted = require("busted")
    local handler = require("busted.outputHandlers.base")()

    local root = os.getenv("BUSTED_PROFILER_FLAMEGRAPH_OUTPUT_PATH")

    if not root then
        error("Cannot write profile results. $BUSTED_PROFILER_FLAMEGRAPH_OUTPUT_PATH is not defined.", 0)
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

        _P.write_all_summary_directory(vim.fs.joinpath(root, "benchmarks", "all"))
        -- _P.write_by_release_directory(vim.fs.joinpath(root, "benchmarks", "by_release"))
    end

    ---@param element busted.Element The `describe` / `it` / etc that just completed.
    ---@param parent busted.Element The `describe` block that includes `element`.
    handler.testStart = function(element, parent)
        table.insert(_NAME_STACK, element.name)

        _TEST_CACHE[_P.get_current_test_path()] = clock()
    end

    ---@param element busted.Element The `describe` / `it` / etc that just completed.
    ---@param parent busted.Element The `describe` block that includes `element`.
    handler.testEnd = function(element, parent)
        _P.handle_test_end()

        table.remove(_NAME_STACK)
    end

    ---@param element busted.Element The `describe` / `it` / etc that just completed.
    ---@param parent busted.Element The `describe` block that includes `element`.
    handler.testFailure = function(element, parent)
        _P.handle_test_end()
    end

    ---@param element busted.Element The `describe` / `it` / etc that just completed.
    ---@param parent busted.Element The `describe` block that includes `element`.
    handler.testError = function(element, parent)
        _P.handle_test_end()
    end

    ---@param element busted.Element The `describe` / `it` / etc that just completed.
    ---@param parent busted.Element The `describe` block that includes `element`.
    handler.error = function(element, parent)
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
