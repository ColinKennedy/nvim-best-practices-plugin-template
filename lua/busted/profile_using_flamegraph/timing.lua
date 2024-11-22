--- Convert flamegraph event data into a "profile summary" page.
---
---@module 'busted.profile_using_flamegraph.timing'
---

local self_timing = require("busted.profile_using_flamegraph.self_timing")
local tabler = require("plugin_template._core.tabler")

---@class _ProfilerLine The data for a row of the user's final profiler report.
---@field count number The number of times that the function was called.
---@field name string The full name of the function.
---@field self_time number The time that a function took (without considering child function calls).
---@field total_time number The time that a function took to run, with its child function calls.

---@class _ProfileReportOptions All user settings to customize the report.
---@field threshold number? A 1-or-more value. The "top slowest" functions to show.
---@field predicate (fun(event: _ProfileEvent): boolean)? Returns `true` to display an event.
---@field sections _ProfileReportSection[]? The columns to include in the output report.

---@class _ProfilerReportPaddings The computed spacing needed for each column.
---@field count number The padding needed to show the "count" column.
---@field name number The padding needed to show the "name" (function name) column.
---@field self_time number The padding needed to show the "self-time" column.
---@field total_time number The padding needed to show the "total-time" column.

---@class _SelfTotalTimes The self-time and total-time.
---@field [1] number Self-time.
---@field [2] number Total-time.

local _P = {}
local M = {}

---@enum _ProfileReportSection
local _Section = {
    count = "count",
    name = "name",
    self_time = "self_time",
    total_time = "total_time",
}

local _SectionLabel = {
    count = "count",
    name = "name",
    self_time = "self-time",
    total_time = "total-time",
}

-- This is meant to be a number that we shouldn't be able to actually hit
local _DEFAULT_PRECISION = 99999999999999
local _DEFAULT_SECTIONS = { _Section.count, _Section.total_time, _Section.self_time, _Section.name }
local _PLUGIN_PREFIX = "plugin_template"

--- Find the amount of characters needed to display `number`.
---
---@param value number Some number to check. e.g. `1234`, `1.234`, etc.
---@return number # The space needed. e.g. `1234`=4, `1.234`=5, etc.
---
function _P.get_digits_count(value)
    return #tostring(value)
end

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

--- Compute all padding needed to display the timing information with uniform columns.
---
---@param lines _ProfilerLine[] The computed data (that will later become the report).
---@return number # A 1-or-more padding value for a function's call-count.
---@return number # A 1-or-more padding value for a function's total-time.
---@return number # A 1-or-more padding value for a function's self-time.
---@return number # A 1-or-more padding value for a function's name.
---@return number # The total time that all functions took to run.
---
function _P.get_header_data(lines)
    local count_padding = 0
    local name_padding = 0
    local self_time_padding = 0
    local total_time = 0
    local total_time_padding = 0

    for _, line in ipairs(lines) do
        count_padding = math.max(count_padding, _P.get_digits_count(line.count))
        name_padding = math.max(name_padding, #line.name)
        self_time_padding = math.max(self_time_padding, _P.get_digits_count(line.self_time))
        total_time_padding = math.max(total_time_padding, _P.get_digits_count(line.total_time))
        total_time = total_time + line.total_time
    end

    return count_padding, total_time_padding, self_time_padding, name_padding, total_time
end

--- Create the header text. While we do that, also compute padding information.
---
---@param lines _ProfilerLine[] The computed data (that will later become the report).
---@param precision number? The number of decimal point digits to show, if any.
---@return string # The blob of header text.
---@return _ProfilerReportPaddings # All of the column padding data.
---
function _P.get_header_text(lines, precision)
    local _get_cropped_max = function(precision_)
        local maxer = function(left, right)
            return math.min(math.max(left, right), precision_)
        end

        return maxer
    end

    -- TODO: This precision code doesn't actually work. Fix it later
    precision = precision or _DEFAULT_PRECISION

    local get_max = _get_cropped_max(precision)
    local output = ""
    -- TODO: total_time is bugged. It only shows the total from `lines`. And
    -- `lines` is a subset of the real events. It doesn't talk about the total
    -- across all functions
    --
    local count_padding, total_time_padding, self_time_padding, name_padding, total_time = _P.get_header_data(lines)
    local count_label = "count"
    local name_label = "name"
    local self_time_label = "self-time"
    local total_time_label = "total-time"
    count_padding = get_max(count_padding, #count_label)
    name_padding = get_max(name_padding, #name_label)
    self_time_padding = get_max(self_time_padding, #self_time_label)
    total_time_padding = get_max(total_time_padding, #total_time_label)

    -- TODO: Consider precision here. e.g. crop at the hundreths place
    local summary_line = ("%%-%ds %%-%ds %%-%ds %%-%ds")
        :format(count_padding, total_time_padding, self_time_padding, name_padding)
        :format(count_label, total_time_label, self_time_label, name_label)

    local full_padding = #summary_line
    local top_line = ("%%-%ds %%7.2f"):format(full_padding - #total_time_label + 2):format(total_time_label, total_time)
    local line_break = ("─"):rep(full_padding) .. "\n"
    output = output .. line_break
    output = output .. top_line .. "\n"
    output = output .. line_break
    output = output .. summary_line .. "\n"
    output = output .. line_break

    return output,
        {
            count = count_padding,
            full = full_padding,
            name = name_padding,
            self_time = self_time_padding,
            total_time = total_time_padding,
        }
end

--- Combine all `paddings` that are found in `sections` into a formattable template.
---
---@param paddings _ProfilerReportPaddings All of the column padding data.
---@param sections _ProfileReportSection[] The columns to show in the template.
---@return string # The generated template. e.g. `"%-10s %-5s"`, etc.
---
function _P.get_line_template(paddings, sections)
    ---@type string[]
    local output = {}

    for _, section in ipairs(sections) do
        table.insert(output, string.format("%%-%ds", paddings[section]))
    end

    return vim.fn.join(output, " ")
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

--- Make sure `self_times` don't have any out-of-bounds values.
---
--- Note:
---     In the future we probably don't need this function. For now it exists just so
---     we can make sure real code doesn't contain unexpected results.
---
--- Raises:
---     If at least one bad self-time was found.
---
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
                    .. "that are greater than the total possible time, which cannot be possible.",
                vim.inspect(greater_than_total_time)
            ),
            0
        )
    end
end

--- Get `events` as summary lines.
---
---@param events _ProfileEvent[] All of the profiler event data to consider.
---@param options _ProfileReportOptions All user settings to customize the report.
---@return _ProfilerLine[] # The computed data (that will later become the report).
---
function M.get_profile_report_lines(events, options)
    local predicate = options.predicate or _P.is_plugin_function
    local threshold = options.threshold or 20
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

        table.insert(output, {
            count = count,
            name = name,
            self_time = self_time,
            total_time = entry.dur,
        })
    end

    return output
end

--- Get `events` as a summary.
---
---@param events _ProfileEvent[] All of the profiler event data to consider.
---@param options _ProfileReportOptions? All user settings to customize the report.
---@return string # The generated report, in human-readable format.
---
function M.get_profile_report_as_text(events, options)
    options = options or {}
    local lines = M.get_profile_report_lines(events, options)

    local header, paddings = _P.get_header_text(lines)
    local line_template = _P.get_line_template(paddings, options.sections or _DEFAULT_SECTIONS) .. "\n"

    local output = header

    for _, line in ipairs(lines) do
        output = output .. string.format(line_template, line.count, line.total_time, line.self_time, line.name)
    end

    return output
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
