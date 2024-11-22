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
---@field precision number? A 0-or-more value and the number of decimal places to show. 0 means "show all decimals".
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
local _DEFAULT_PRECISION = 2
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
---@param precision number? The number of decimal point digits to show, if any.
---@return _ProfilerReportPaddings # All of the column padding data.
---@return number # The total time that all functions took to run.
---
function _P.get_header_padding_data(lines, precision)
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

    return {
        count = count_padding,
        name = name_padding,
        self_time = self_time_padding,
        total_time = total_time_padding,
    }, total_time
end

--- Create the header text. While we do that, also compute padding information.
---
---@param lines _ProfilerLine[] The computed data (that will later become the report).
---@param sections _ProfileReportSection[] The columns to show in the template.
---@return string # The blob of header text.
---@return _ProfilerReportPaddings # All of the column padding data.
---
function _P.get_header_text(lines, sections)
    local output = ""

    local paddings, total_time = _P.get_header_padding_data(lines)
    ---@type string[]
    local summary_labels = {}
    local computed_paddings = {}

    for _, section in ipairs(sections) do
        local label = _SectionLabel[section]
        local suggested_padding = paddings[section]
        local padding = math.max(suggested_padding, #label)
        computed_paddings[section] = padding
        table.insert(summary_labels, ("%%-%ds"):format(padding):format(label))
    end

    local summary_line = vim.fn.join(summary_labels, " ")

    -- TODO: total_time is bugged. It only shows the total from `lines`. And
    -- `lines` is a subset of the real events. It doesn't talk about the total
    -- across all functions

    local full_padding = #summary_line
    -- TODO: Add precision here. e.g. crop at the hundreths place
    local top_line = ("%%-%ds %%7.2f"):format(full_padding - #_SectionLabel.total_time + 2):format(_SectionLabel.total_time, total_time)
    local line_break = ("─"):rep(full_padding) .. "\n"
    output = output .. line_break
    output = output .. top_line .. "\n"
    output = output .. line_break
    output = output .. summary_line .. "\n"
    output = output .. line_break

    return output, computed_paddings
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

--- Strip excess decimals off of `value` according to `precision`.
---
---@param value number Some float to crop. e.g. `123.06789`.
---@param precision number The number of decimals to keep. e.g. `123.06789`. 0 means "don't crop".
---@return string # The output, e.g. `"123.07"`.
---
function _P.crop_to_precision(value, precision)
    return string.format("%%.%sf", precision):format(value)
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
    local self_times = self_timing.get_self_times(top_slowest, functions)
    _P.validate_self_times(self_times, top_slowest)

    local output = {}

    local precision = options.precision or _DEFAULT_PRECISION

    for _, entry in ipairs(top_slowest) do
        local name = entry.name
        local count = counts[name]
        local self_time = self_times[name]

        table.insert(output, {
            count = count,
            name = name,
            self_time = _P.crop_to_precision(self_time, precision),
            total_time = _P.crop_to_precision(entry.dur, precision),
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
    local sections = options.sections or _DEFAULT_SECTIONS
    local lines = M.get_profile_report_lines(events, options)

    local header, paddings = _P.get_header_text(lines, sections)
    local line_template = _P.get_line_template(paddings, sections) .. "\n"

    local output = header

    for _, line in ipairs(lines) do
        ---@type string[]
        local data = {}

        for _, section in ipairs(sections) do
            table.insert(data, line[section])
        end

        output = output .. string.format(line_template, unpack(data))
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
