--- Convert flamegraph event data into a "profile summary" page.
---
---@module 'busted.profile_using_flamegraph.timing'
---

local self_timing = require("busted.profile_using_flamegraph.self_timing")
local tabler = require("plugin_template._core.tabler")

local _P = {}
local M = {}

---@class _SelfTotalTimes The self-time and total-time.
---@field [1] number Self-time.
---@field [2] number Total-time.

local _PLUGIN_PREFIX = "plugin_template"

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

    local _ALLOWED_NAMES = { _PLUGIN_PREFIX }

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

--- Collect `events` based on the total time across all `events`.
---
---@param events _ProfileEvent[] All of the profiler event data to consider.
---@param predicate (fun(event: _ProfileEvent): boolean)? Returns `true` to display an event.
---@return _ProfileEvent[] # All start/end ranges for each time the event was found.
---@return table<string, number> # The number of times that each event was found.
---
function _P.get_totals(events, predicate)
    if not predicate then
        predicate = function(_)
            return true
        end
    end

    ---@type _ProfileEvent[]
    local output_events = {}

    ---@type table<string, number>
    local counts = {}

    for _, event in ipairs(events) do
        if predicate(event) then
            local name = event.name
            counts[name] = (counts[name] or 0) + 1
            table.insert(output_events, event)
        end
    end

    return output_events, counts
end

---@param self_times table<string, number> Each event name and its computed self-time.
---@param events _ProfileEvent[] All of the events to consider.
---
function _P.validate_self_times(self_times, events)
    ---@type table<string, number>
    local events_by_time = {}

    for _, event in ipairs(events) do
        events_by_time[event.name] = event.dur
    end

    ---@type table<string, number>
    local less_than_zero = {}

    ---@type table<string, _SelfTotalTimes>
    local greater_than_total_time = {}

    for name, self_time in pairs(self_times) do
        if self_time < 0 then
            less_than_zero[name] = self_time
        elseif self_time > events_by_time[name] then
            greater_than_total_time[name] = { self_time, events_by_time[name] }
        end
    end

    if not vim.tbl_isempty(less_than_zero) then
        error(
            string.format(
                'Bug: Invalid self-times were found. "%s" events are less than zero, which cannot be possible.',
                vim.inspect(less_than_zero)
            ),
            0
        )
    end

    if not vim.tbl_isempty(greater_than_total_time) then
        error(
            string.format(
                'Bug: Invalid self-times were found. "%s" events have self times '
                .. 'that are greater than the total possible time, which cannot be possible.',
                vim.inspect(greater_than_total_time)
            ),
            0
        )
    end
end

--- Get `events` as summary lines.
---
---@param events _ProfileEvent[] All of the profiler event data to consider.
---@param threshold number? A 1-or-more value. The "top slowest" functions to show.
---@param predicate (fun(event: _ProfileEvent): boolean)? Returns `true` to display an event.
---@return string[] # The generated report, in human-readable format.
---
function M.get_profile_report_lines(events, threshold, predicate)
    predicate = predicate or _P.is_plugin_function
    threshold = threshold or 20
    local functions, counts = _P.get_totals(events, predicate)

    local slowest_functions = vim.fn.sort(functions, function(left, right)
        return left.dur < right.dur
    end)

    ---@cast slowest_functions _ProfileEvent[]

    local top_slowest = tabler.get_slice(slowest_functions, 1, threshold)
    local self_times = self_timing.get_self_times(top_slowest, slowest_functions)
    _P.validate_self_times(self_times, top_slowest)

    local output = {}

    for _, entry in ipairs(top_slowest) do
        local name = entry.name
        local count = counts[name]
        local self_time = self_times[name]

        -- TODO: Make this better formatted, later
        table.insert(output, string.format("%s %s %s %s", count, entry.dur, self_time, name))
    end

    return output
end

--- Get `events` as a summary.
---
---@param events _ProfileEvent[] All of the profiler event data to consider.
---@param threshold number? A 1-or-more value. The "top slowest" functions to show.
---@return string # The generated report, in human-readable format.
---
function M.get_profile_report_as_text(events, threshold)
    local lines = M.get_profile_report_lines(events, threshold)

    return string.format("Total Time:\n%s", vim.fn.join(lines, "\n"))
end

-- local function main()
--     -- TODO: Remove this test later
--     -- local path = "/tmp/directory/benchmarks/all/artifacts/2024_11_18-00_16_00-v1.2.3/profile.json"
--     -- local path = "/tmp/directory/benchmarks/all/flamegraph.json"
--     -- {"tid":1,"ph":"X","ts":164155.201,"args":{"3":"Parameter \"É§elp\"
--     cannot use
--     action=\"store_true\".","2":1,"n":3},
--     "dur":1.2000000000116,"cat":"function","pid":1,"name":"luassert.util.tinsert"},
--     local path = "/tmp/directory/benchmarks/all/flamegraph.json"
--     local file = io.open(path, "r")
--     if not file then error("STOP", 0) end
--     local raw_data = file:read("*a")
--     file:close()
--     local data = vim.json.decode(raw_data)
--     print(M.get_profile_report(data))
-- end
--
-- main()

return M
