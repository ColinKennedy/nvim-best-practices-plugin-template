-- TODO: Docstring

local helper = require("busted.profile_using_flamegraph.helper")
local instrument = require("profile.instrument")
local profile = require("profile")

local _P = {}

function _P.clear_arg()
    for key, _ in pairs(arg) do
        if key ~= 0 then
            arg[key] = nil
        end
    end
end

function _P.keep_arg(caller)
    local original = vim.deepcopy(arg)

    caller()

    for key, value in pairs(original) do
        arg[key] = value
    end
end

function _P.profile_and_run(runner)
    local before = os.clock()
    profile.start("*")
    _P.run_busted_suite(runner)
    profile.stop()

    return os.clock() - before
end

function _P.reset_busted_packages()
    package.loaded["busted"] = nil
    package.loaded["busted.runner"] = nil

    -- for key, _ in pairs(package.loaded) do
    --     if key == "busted" or string.sub(key, 1, 7) == "busted." then
    --         package.loaded[key] = nil
    --     end
    -- end
end

function _P.run_busted_suite(runner, options)
    _P.keep_arg(function()
        _P.clear_arg()

        arg[1] = "--ignore-lua"
        arg[2] = "--helper=spec/minimal_init.lua"
        arg[3] = "--output=busted.profile_using_flamegraph"

        runner({ standalone=false })
    end)
end

local function main()
    local maximum_tries = 10
    local counter = 10
    local fastest_time = 2^1023
    local fastest_events = nil

    while true do
        _P.reset_busted_packages()
        local runner = require("busted.runner")

        local duration = _P.profile_and_run(runner)

        if duration < fastest_time then
            counter = maximum_tries
            fastest_time = duration
            -- TODO: CHECK if copying here is actually needed
            fastest_events = vim.deepcopy(instrument.get_events())
        else
            counter = counter - 1
        end

        if counter == 0 then
            break
        end
    end

    if not fastest_events then
        error("Something went wrong. We didn't find any profiler events to record.", 0)
    end

    helper.write_all_summary_directory(release, profile, vim.fs.joinpath(root, "benchmarks", "all"))
end

main()
