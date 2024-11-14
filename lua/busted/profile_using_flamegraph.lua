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

-- TODO: Add logging in this file / around

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
---     Or if the given `maximum` is invalid.
---
---@param root string
---    An absolute path to the direct-parent directory. e.g. `".../benchmarks/all/artifacts".
---@param maximum number?
---    The number of artifacts to read. If not provided, read all of them.
---@return _GraphArtifact[]
---    All found records so far, if any.
---
function _P.get_graph_artifacts(root, maximum)
    if maximum ~= nil then
        if maximum < 1 then
            error(string.format('Maximum "%s" must be >= 1', maximum), 0)
        end
    else
        maximum = 2 ^ 40 -- NOTE: Just some arbitrary, really big number
    end

    ---@type _GraphArtifact[]
    local output = {}

    local template = vim.fs.joinpath(root, "*", _DETAILS_FILE_NAME)

    for index, path in ipairs(_P.get_sorted_datetime_paths(vim.fn.glob(template, false, true))) do
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

        if index >= maximum then
            -- TODO: Add logging
            return output
        end
    end

    return output
end

--- Read `"/path/to/2024_08_23-11_03_01/foo.bar"` for the date + time data.
---
---@param path string The absolute path to a file. Its parent directory has date + time data.
---@return number[] # All of the date information.
---
function _P.get_parent_directory_name_data(path)
    local text = vim.fn.fnamemodify(vim.fn.fnamemodify(path, ":h"), ":t")

    local output = {}

    for number_text in string.gmatch(text, "%d+") do
        table.insert(output, tonumber(number_text))
    end

    if #output < 6 then
        error(string.format('Text "%s" did not match "YYYY_MM_DD-vMAJOR.MINOR.PATCH" pattern.', text), 0)
    end

    return output
end

--- Sort all file-paths on-disk based on their date + time data.
---
--- We assume that these paths follow a format similar to
--- `"/path/to/2024_08_23-11_03_01/foo.bar"`.
---
---@param paths string[] All of the absolute paths on-disk to sort.
---@return string[] # All sorted paths, in ascending order.
---
function _P.get_sorted_datetime_paths(paths)
    return vim.fn.sort(paths, function(left, right)
        if left == right then
            return 0
        end

        return _P.compare_number_arrays(
            _P.get_parent_directory_name_data(left),
            _P.get_parent_directory_name_data(right)
        )
    end)
end

--- Add graph data to the "benchmarks/all/README.md" file.
---
--- Or create the file if it does not exist.
---
---@param data _SummaryTimingLine Some timing data to append to the README.md's markdown table.
---@param path string The path on-disk to write the README.md to.
---@param release string A version / release tag. e.g. `"v1.2.3"`.
---
function _P.append_to_summary_readme(data, path, release)
    -- TODO: Change the code for the summary README.md - Make it easy for anyone
    -- their own "highlight this specific thing that I want to track" API.
    _P.create_summary_readme_if_needed(path)

    local file = io.open(path, "a")

    if not file then
        error(string.format('Cannot append to "%s" path.', path), 0)
    end

    local platform = vim.loop.os_uname().sysname
    -- TODO: To the get CPU
    -- TODO: Maybe vim.uv.cpu_info() but really we should use something better here
    -- https://docs.python.org/3/library/platform.html#platform.processor
    local cpu = "TODO"

    file:write(
        string.format(
            "| %s | %s | %s | %s | %s | %s | %s |\n",
            release,
            platform,
            cpu,
            data.total,
            data.median,
            data.mean,
            data.standard_deviation
        )
    )
end

--- Check if `left` should be sorted before `right`.
---
--- This function follows the expected outputs of Vim's built-in sort function.
--- See the "{how}" section within `:help sort()` for details.
---
---@param left number[]
---    All of the numbers to compare.
---@param right number[]
---    All of the numbers to compare. We expect this value to come to the right.
---@return number
---    A number that indicates the sorting position. 0 == `left` comes neither
---    before or after `right`. 1 == `left` comes after `right`. -1 == `left`
---    comes before `right`.
---
function _P.compare_number_arrays(left, right)
    local left_count = #left
    local right_count = #right

    for index = 1, math.min(left_count, right_count) do
        if left[index] < right[index] then
            return -1
        elseif left[index] > right[index] then
            return 1
        end
    end

    if left_count < right_count then
        return -1 -- left is smaller because it has fewer elements
    elseif left_count > right_count then
        return 1 -- left is greater because it has more elements
    end

    return 1
end

--- Copy `source` file on-disk to the `destination` directory.
---
--- The copied file has the same file name as `source`.
---
---@param source string Some file to copy. e.g. `"/foo/bar.txt".
---@param destination string A directory to copy into. e.g. `"/fizz"`.
---
function _P.copy_file_to_directory(source, destination)
    local source_file = io.open(source, "r")

    if not source_file then
        error(string.format('Cannot open "%s" file.', source), 0)
    end

    local data = source_file:read("*a")

    source_file:close()

    local destination_file = io.open(vim.fs.joinpath(destination, vim.fn.fnamemodify(source, ":t")), "w")

    if not destination_file then
        error(string.format('Cannot open "%s" file.', destination), 0)
    end

    destination_file:write(data)
    destination_file:close()
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

--- Get all input data needed for us to run + save flamegraph data to-disk.
---
---@return string # The absolute directory on-disk where flamegraph info will be written.
---@return string # The version to write to-disk. e.g. `"v1.2.3"`.
---
function _P.parse_input_arguments()
    local root = os.getenv("BUSTED_PROFILER_FLAMEGRAPH_OUTPUT_PATH")

    if not root then
        error("Cannot write profile results. $BUSTED_PROFILER_FLAMEGRAPH_OUTPUT_PATH is not defined.", 0)
    end

    -- TODO: Provide this env-var to the GitHub workflow using GitHub's ${{
    -- github.event.release.tag_name }} support
    local release = os.getenv("BUSTED_PROFILER_FLAMEGRAPH_VERSION")

    if not release then
        error("Cannot write profile results. $BUSTED_PROFILER_FLAMEGRAPH_VERSION is not defined.", 0)
    end

    _P.validate_release(release)

    return root, release
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

--- Make sure `version` is an expected semantic version convention.
---
--- Raises:
---     If `version` isn't a valid convention.
---
---@param version string A release / version tag. e.g. `"v1.2.3"`.
---
function _P.validate_release(version)
    local pattern = "^v%d+%.%d+%.%d+$"

    if not string.match(version, pattern) then
        error(
            string.format('Version "%s" is invalid. Expected Semantic Versioning. See semver.org for details.', version),
            0
        )
    end
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
---@param release string The current release to make. e.g. `"v1.2.3"`.
---@param profiler Profiler The object used to record function call times.
---@param root string The ".../benchmarks/all" directory to create or update.
---
function _P.write_all_summary_directory(release, profiler, root)
    local flamegraph_path, profile_path, profile_data = _P.write_graph_artifact(release, profiler, root)

    _P.copy_file_to_directory(flamegraph_path, root)
    _P.copy_file_to_directory(profile_path, root)

    _P.append_to_summary_readme(profile_data, vim.fs.joinpath(root, "README.md"), release)
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
---@param release string The current release to make. e.g. `"v1.2.3"`.
---@param profiler Profiler The object used to record function call times.
---@param root string The ".../benchmarks/all" directory to create or update.
---
function _P.write_graph_artifact(release, profiler, root)
    local directory = vim.fs.joinpath(root, string.format("%s-%s", os.date("%Y_%m_%d-%H_%M_%S"), release))
    vim.fn.mkdir(directory, "p")

    local flamegraph_path = vim.fs.joinpath(directory, "flamegraph.json")
    _P.write_flamegraph(profiler, flamegraph_path)

    local profile_path = vim.fs.joinpath(directory, "profile.json")
    local profile_data = _P.write_profile_summary(profile_path)

    return flamegraph_path, profile_path, profile_data
end

-- TODO: Missing docstring return value
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
        median = 1.45,
        standard_deviation = 1.78,
        total = 1.90,
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

    local root, release = _P.parse_input_arguments()

    profile.start("*")

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

        _P.write_all_summary_directory(release, profile, vim.fs.joinpath(root, "benchmarks", "all"))
        -- TODO: Finish this part
        -- _P.write_by_release_directory(vim.fs.joinpath(root, "benchmarks", "by_release"))
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
