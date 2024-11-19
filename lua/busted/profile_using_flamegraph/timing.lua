--- Convert flamegraph event data into a "profile summary" page.
---
---@module 'busted.profile_using_flamegraph.timing'
---

local self_timing = require("busted.profile_using_flamegraph.self_timing")
local tabler = require("plugin_template._core.tabler")

local _P = {}
local M = {}

local _PLUGIN_PREFIX = "plugin_template"

-- TODO: Docstring
---@class _ProfileEventSummary[]
---@field duration number
---@field name string

--- Check if this plugin defined this `event` function.
---
---@param event _ProfileEvent
---    The profiler event to check. It might be a function, or describe block
---    or anything else.
---@return boolean
---    If `event` is defined here, return `true`. Otherwise if it is an
---    external function or a Neovim core function, return `false`.
---
function _P.is_plugin_function(event)
    if not event.cat or event.cat ~= "function" then
        return false
    end

    local _ALLOWED_NAMES = {_PLUGIN_PREFIX}

    if vim.tbl_contains(_ALLOWED_NAMES, event.name) then
        return true
    end

    for _, name in ipairs(_ALLOWED_NAMES) do
        if string.match(event.name, name .. "%.") then
            return true
        end
    end

    return false
end

--- Find out how much time a function took to run.
---
--- If a function calls another function, that function's inner time is
--- substracted from the outer function's self-time. So you can see, clearly,
--- which functions are actually slow and which functions are simply slow
--- because they call other (slow) functions.
---
--- Important:
---     This function expects `events` and `all_events` to be ascended-sorted!
---
---@param events _ProfileEvent[] All of the profiler event data to compute self-time for.
---@param all_events _ProfileEvent[] All reference profiler event data.
---@return table<string, number> # Each event name and its computed self-time.
---
function _P.get_self_times(events, all_events)
    ---@type table<string, number>
    local output = {}

    -- Let's explain what this is doing.
    --
    -- Each event log has a start time, labelled `ts`.
    -- We assume that all events are sorted from the earliest to the latest start time.
    --
    -- - We then keep track of the **first** index that is **after** that start time
    --     - We have to do this on a per-thread basis, to account for multi-threaded code
    -- - For each event that we must compute self-time
    --     - From the starting index, check each range until we find a range
    --       that is just after the start time
    --         - This range is a direct child of the event. We know this
    --           because the ranges were **sorted in advance**.
    --     - Search the ranges until we find a range that is beyond that previous range's end time.
    --         - All previous ranges were function "calls-within-calls" and can be ignored
    --             - Again, we can do this because ranges were **sorted in advance**
    --     - Set the starting index to that later range's index
    --     - Repeat with the next event. We use the new staring index to avoid
    --       scanning all ranges from scratch again.
    --
    -- Using this technique, we find all direct children for all events. We
    -- then subtract the direct child durations to compute each event's
    -- self-time.

    --- Each thread ID and the index to start searching within `ranges`.
    ---@type table<number, number>
    ---
    local starting_indices = {}
    local all_events_count = #all_events

    for _, event in ipairs(vim.fn.sort(events, function(left, right) return left.ts < right.ts end)) do
        ---@cast event _ProfileEvent

        local starting_index = _P.get_next_starting_index(
            event,
            (starting_indices[event.tid] or 1),
            all_events,
            all_events_count
        )

        if starting_index == self_timing.NOT_FOUND_INDEX then
            -- TODO: Add logging

            -- NOTE: If we're on the very last event and there are no other events then it means
            -- 1. We're on the very last call that was profiled.
            -- 2. That last function is also a leaf function (it doesn't call anything else).
            --
            -- This should be a really rare occurrence. But could happen.
            --
            output[event.name] = event.dur
        end

        local event_end_time = event.ts + event.dur

        -- TODO: Need to handle this part better. Somehow
        while all_events[starting_index].ts < event_end_time do
            local reference_event = all_events[starting_index]
            local reference_event_end_time = reference_event.ts + reference_event.dur
            local reference_thread_id = reference_event.tid

            for index=starting_index + 1,all_events_count do
                local next_reference_event = all_events[index]

                if next_reference_event.tid == reference_thread_id and next_reference_event.ts > reference_event_end_time then
                    starting_indices[reference_event.tid] = index
                    starting_index = index

                    break
                end
            end
        end
    end

    return output
end

--- Collect `events` based on the total time across all `events`.
---
---@param events _ProfileEvent[] All of the profiler event data to consider.
---@param predicate (fun(event: _ProfileEvent): boolean)? Returns `true` to display an event.
---@return _ProfileEventSummary[] # Each event name and its total time taken.
---@return _ProfileEvent[] # All start/end ranges for each time the event was found.
---@return table<string, number> # The number of times that each event was found.
---
function _P.get_totals(events, predicate)
    if not predicate then
        predicate = function(_) return true end
    end

    ---@type table<string, number>
    local totals = {}

    ---@type _ProfileEvent[]
    local ranges = {}

    ---@type table<string, number>
    local counts = {}

    for _, event in ipairs(events) do
        if predicate(event) then
            local name = event.name
            totals[name] = (totals[name] or 0) + event.dur
            counts[name] = (counts[name] or 0) + 1
            table.insert(ranges, event)
        end
    end

    ---@type _ProfileEventSummary[]
    local functions = {}

    for name, total in pairs(totals) do
        table.insert(functions, {duration=total, name=name})
    end

    return functions, ranges, counts
end

--- Print `events` as a summary.
---
---@param events _ProfileEvent[] All of the profiler event data to consider.
---@param threshold number? A 1-or-more value. The "top slowest" functions to show.
---@return string # The generated report, in human-readable format.
---
function M.get_profile_report(events, threshold)
    threshold = threshold or 20
    -- TODO: Remove ranges
    local functions, ranges, counts = _P.get_totals(events, _P.is_plugin_function)

    local slowest_functions = vim.fn.sort(functions, function(left, right)
        return left.duration < right.duration
    end)

    local top_slowest = tabler.get_slice(slowest_functions, 1, threshold)
    local self_times = _P.get_self_times(top_slowest, slowest_functions)
    local lines = {}

    for _, entry in ipairs(top_slowest) do
        local name = entry.name
        local count = counts[name]
        local self_time = self_times[name]
        local total_time = entry.duration

        -- TODO: Make this better formatted, later
        table.insert(lines, string.format("%s %s %s %s", count, total_time, self_time, name))
    end

    return string.format("Total Time:\n%s", vim.fn.join(lines, "\n"))
end

local function main()
    -- TODO: Remove this test later
    -- local path = "/tmp/directory/benchmarks/all/artifacts/2024_11_18-00_16_00-v1.2.3/profile.json"
    -- local path = "/tmp/directory/benchmarks/all/flamegraph.json"
    -- {"tid":1,"ph":"X","ts":164155.201,"args":{"3":"Parameter \"É§elp\" cannot use action=\"store_true\".","2":1,"n":3},"dur":1.2000000000116,"cat":"function","pid":1,"name":"luassert.util.tinsert"},
    local path = "/tmp/directory/benchmarks/all/flamegraph.json"
    local file = io.open(path, "r")
    if not file then error("STOP", 0) end
    local raw_data = file:read("*a")
    file:close()
    local data = vim.json.decode(raw_data)
    print(M.get_profile_report(data))
end

main()

return M
