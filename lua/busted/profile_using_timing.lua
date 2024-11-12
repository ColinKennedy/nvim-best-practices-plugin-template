-- TODO: Add docstrings

-- :profile start /tmp/profile2.txt | profile func * | profile file *
-- :profile pause /tmp/profile2.txt | profile func * | profile file *

local instrument = require("profile.instrument")
local profile = require("profile")
local tabler = require("plugin_template._core.tabler")

---@class profile.Entry A quick, sparse way to refer to a function call.
---@field duration number The time taken (in milliseconds) for the function to run.
---@field name string The function that was called.

---@class _TimeRange Some starting point and ending point, in milliseconds.
---@field start number The first millisecond of the time range, (inclusive).
---@field end number The last millisecond of the time range, (inclusive).

local _PLUGIN_PREFIX = "plugin_template."

local function _get_function_details(totals)
    -- NOTE: Consider allowing other functions here in the future?
    local predicate = function(entry)
        return vim.startswith(entry, _PLUGIN_PREFIX)
    end

    ---@type table<string, number>
    local counts = {}

    ---@type profile.Entry[]
    local functions = {}

    for name, total_duration in pairs(totals) do
        ---@type profile.Entry
        local entry = { duration = total_duration, name = name }

        if predicate(entry) then
            table.insert(functions, entry)
            counts[entry.name] = (counts[entry.name] or 0) + 1
        end
    end

    return counts, functions
end

local function _get_totals(events)
    ---@type table<string, number>
    local totals = {}

    ---@type table<string, _TimeRange[]>
    local ranges = {}

    for _, event in ipairs(events) do
        if event.cat and event.cat == "function" then
            local name = event.name
            totals[name] = (totals[name] or 0) + event.dur

            if not ranges[name] then
                ranges[name] = {}
            end

            table.insert(ranges[name], { start = event.ts, ["end"] = event.ts + event.dur })
        end
    end

    return totals, ranges
end

-- TODO: Add support for this later
local function _get_self_times(entries, ranges)
    -- for _, entry in ipairs(entries) do
    --     entry.name
    -- end
end

local function _get_profile_report(events)
    local totals, ranges = _get_totals(events)
    local counts, functions = _get_function_details(totals)

    local slowest_functions = vim.fn.sort(functions, function(left, right)
        return left.duration < right.duration
    end)
    local threshold = 20
    local top_slowest = tabler.get_slice(slowest_functions, 1, threshold)
    -- TODO: Add support for self_times later
    -- local self_times = _get_self_times(top_slowest, ranges)

    for _, entry in ipairs(top_slowest) do
        local name = entry.name
        local count = counts[name]
        -- TODO: Add support for self_times later
        -- local self_time = self_times[name]
        local total_time = entry.duration

        -- TODO: Make this better formatted, later
        print(string.format("%s %s %s", count, total_time, name))

        -- TODO: Add support for self_time, later
        -- -- TODO: Make this better formatted, later
        -- print(string.format("%s %s %s %s", count, total_time, self_time, name))
    end

    return string.format("Total Time:\n")
end

local function _write(report, path)
    local file = io.open(path, "w")

    if not file then
        vim.notify(string.format('Failed to open "%s" path for writing.', path), vim.log.levels.ERROR)

        return
    end

    file:write(report)
    file:close()

    vim.notify(string.format('Wrote the report to "%s" path.', path), vim.log.levels.INFO)
end

--- Create an output handler (that records profiling data and outputs it afterwards).
---
---@param options busted.CallerOptions The user-provided terminal statistics.
---@return busted.Handler # The generated handler.
---
return function(options)
    local busted = require("busted")
    local handler = require("busted.outputHandlers.base")()

    local export_path = os.getenv("BUSTED_PROFILER_TIMING_OUTPUT_PATH")

    if not export_path then
        error("Cannot write profile results. $BUSTED_PROFILER_FLAMEGRAPH_OUTPUT_PATH is not defined.")
    end

    profile.start("*")

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

        vim.notify('Writing profile output to "%s" path.', export_path)

        local report = _get_profile_report(instrument.get_events())
        _write(report, path)
    end

    busted.subscribe({ "suite", "end" }, handler.suiteEnd)

    return handler
end
