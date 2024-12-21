--- A modified `busted` unittest suite runner.
---
--- It runs tests multiple times and, each time, records profiler and timing results.
---
---@module 'busted.profiler_runner'
---

local helper = require("busted.profile_using_flamegraph.helper")
local instrument = require("profile.instrument")
local profile = require("profile")
local vlog = require("plugin_template._vendors.vlog")

local _LOGGER = vlog.get_logger("busted.profiler_runner")
local _P = {}

--- Delete all Lua terminal-provided arguments (so we can replace them later).
function _P.clear_arg()
    for key, _ in pairs(arg or {}) do
        if key ~= 0 then
            arg[key] = nil
        end
    end
end

--- Remember Lua's user arguments and restore them later.
---
---@param caller fun(): nil Any function to call in the middle.
---
function _P.keep_arg(caller)
    local original = vim.deepcopy(arg or {})

    caller()

    for key, value in pairs(original) do
        arg[key] = value
    end
end

--- Run the tests, once, and gather profile / timing data while we do it.
---
---@param profiler Profiler The object used to record function call times.
---@param runner busted.MultiRunner A unittest suite runner to call.
---@param options busted.MultiRunnerOptions? The settings to apply to the runner.
---
function _P.profile_and_run(profiler, runner, options)
    local before = vim.uv.hrtime()
    profiler.start()
    _P.run_busted_suite(runner, options)
    profiler.stop()

    return vim.uv.hrtime() - before
end

--- Remove any caches that would prevent us from running busted multiple times.
---
--- In truth we don't know why busted was written / designed to be called only
--- once. But we can get around it by calling this function.
---
function _P.reset_busted_packages()
    package.loaded["busted"] = nil
end

--- Run the tests, once.
---
---@param runner busted.MultiRunner A unittest suite runner to call.
---@param options busted.MultiRunnerOptions? The settings to apply to the runner.
---
function _P.run_busted_suite(runner, options)
    _P.keep_arg(function()
        _P.clear_arg()

        arg[1] = "--ignore-lua"
        arg[2] = "--helper=spec/minimal_init.lua"
        arg[3] = "--output=busted.profile_using_flamegraph"

        runner(vim.tbl_deep_extend("force", options or {}, { standalone = false }))
    end)
end

--- Run the unittest multiple times until a "fastest time" is found.
---
--- The logic works like this:
---
--- - Run tests
--- - Get the total test elapsed time
--- - Set our "number of tries" time to `maximum_tries`
--- - If the elapsed time is equal to or took longer compared to the previous best
---     - Decrement our "number of tries" counter
--- - If the elapsed time is less than the previous best...
---     - Record this elapsed time as the previous best
---     - Reset the "number of tries" counter back to `maximum_tries`.
--- - If "number of tries" hits zero, then we've found the fastest time.
---
--- Raises:
---     If `maximum_tries` is invalid.
---
---@param profiler Profiler
---    The object used to record function call times.
---@param release string
---    A version / release tag. e.g. `"v1.2.3"`.
---@param root string
---    An absolute path to the directory on-disk where files are written.
---@param maximum_tries number
---    This controls the number of times that tests can run before we determine
---    that we've found a "fastest" test run. The higher the value, the longer
---    but more accurate this function becomes.
---
local function run_tests(profiler, release, root, maximum_tries)
    if maximum_tries < 1 then
        error(string.format('Maximum tries must be 1-or-more. Got "%s".', maximum_tries), 0)
    end

    local counter = maximum_tries
    local fastest_time = 2 ^ 1023
    local fastest_events = nil

    while true do
        _P.reset_busted_packages()
        local runner = require("busted.multi_runner")
        ---@diagnostic disable-next-line: cast-type-mismatch
        ---@cast runner busted.MultiRunner

        local duration = _P.profile_and_run(profiler, runner, { release = release, root = root })

        if duration < fastest_time then
            _LOGGER:fmt_debug('Faster time found. New: "%s". Old: "%s".', duration, fastest_time)

            counter = maximum_tries
            fastest_time = duration
            -- TODO: CHECK if copying here is actually needed
            fastest_events = vim.deepcopy(instrument.get_events())
        else
            counter = counter - 1
        end

        if counter == 0 then
            _LOGGER:debug("Reached end of the profiler tests.")

            break
        end
    end

    if not fastest_events then
        error("Something went wrong. We didn't find any profiler events to record.", 0)
    end

    helper.write_all_summary_directory(release, profile, vim.fs.joinpath(root, "benchmarks", "all"), fastest_events)
end

--- Run these tests.
local function main()
    local root, release = helper.get_environment_variable_data()

    helper.validate_gnuplot()

    -- NOTE: Don't profile the unittest framework
    local profiler = profile
    profiler.ignore("busted*")

    instrument("*")

    run_tests(profiler, release, root, 10)
end

main()
