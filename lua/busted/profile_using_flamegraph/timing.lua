--- Convert flamegraph event data into a "profile summary" page.
---
---@module 'busted.profile_using_flamegraph.timing'
---

local tabler = require("plugin_template._core.tabler")

local _P = {}
local M = {}

local _PLUGIN_PREFIX = "plugin_template."

-- TODO: Docstring
---@class _ProfileEventSummary[]
---@field duration number
---@field name string

--- Find out how many times a function was called.
---
---@param all_ranges table<string, _TimeRange[]> # Each event name and each of its calls.
---@return table<string, number> # Each function and the number of times it was called.
---
function _P.get_function_counts(all_ranges)
    ---@type table<string, number>
    local output = {}

    for name, ranges in pairs(all_ranges) do
        output[name] = #ranges
    end

    return output
end

--- Find out how much time a function took to run.
---
--- If a function calls another function, that function's inner time is
--- substracted from the outer function's self-time. So you can see, clearly,
--- which functions are actually slow and which functions are simply slow
--- because they call other (slow) functions.
---
---@param events _ProfileEvent[] All of the profiler event data to consider.
---@return table<string, number> # Each event name and its computed self-time.
---
function _P.get_self_times(events, ranges)
    ---@type table<string, number>
    local output = {}

    for _, entry in ipairs(events) do
        -- TODO: When computing self-time, make sure to account for floating point
        -- / rounding errors
        -- TODO: Replace with a real value later
        output[entry.name] = 10
    end

    return output
end

--- Collect `events` based on the total time across all `events`.
---
---@param events _ProfileEvent[] All of the profiler event data to consider.
---@return _ProfileEventSummary[] # Each event name and its total time taken.
---@return table<string, _TimeRange[]> # All start/end ranges for each time the event was found.
---
function _P.get_totals(events)
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

    ---@type _ProfileEventSummary[]
    local functions = {}

    for name, total in pairs(totals) do
        table.insert(functions, {duration=total, name=name})
    end

    return functions, ranges
end

--- Print `events` as a summary.
---
---@param events _ProfileEvent[] All of the profiler event data to consider.
---@param threshold number? A 1-or-more value. The "top slowest" functions to show.
---@return string # The generated report, in human-readable format.
---
function M.get_profile_report(events, threshold)
    threshold = threshold or 20
    local functions, ranges = _P.get_totals(events, {_PLUGIN_PREFIX})
    local counts = _P.get_function_counts(ranges)

    local slowest_functions = vim.fn.sort(functions, function(left, right)
        return left.duration < right.duration
    end)

    local top_slowest = tabler.get_slice(slowest_functions, 1, threshold)
    local self_times = _P.get_self_times(top_slowest, ranges)

    for _, entry in ipairs(top_slowest) do
        local name = entry.name
        local count = counts[name]
        local self_time = self_times[name]
        local total_time = entry.duration

        -- TODO: Make this better formatted, later
        print(string.format("%s %s %s %s", count, total_time, self_time, name))
    end

    return string.format("Total Time:\n")
end

local function main()
    -- TODO: Remove this test later
    -- local path = "/tmp/directory/benchmarks/all/artifacts/2024_11_18-00_16_00-v1.2.3/profile.json"
    -- local path = "/tmp/directory/benchmarks/all/flamegraph.json"
    -- {"tid":1,"ph":"X","ts":164155.201,"args":{"3":"Parameter \"É§elp\" cannot use action=\"store_true\".","2":1,"n":3},"dur":1.2000000000116,"cat":"function","pid":1,"name":"luassert.util.tinsert"},
    local path = "/tmp/directory/benchmarks/all/flamegraph.json"
    local file = io.open(path, "r")
    local raw_data = file:read("*a")
    file:close()
    local data = vim.json.decode(raw_data)
    print(vim.inspect(M.get_profile_report(data)))
end

main()

return M
