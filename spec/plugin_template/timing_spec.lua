--- All (profiler) timing private unittests. These are not API functions.
---
---@module 'spec.plugin_template.timing_spec'
---

-- TODO: Finish the tests here

local _P = {}

local timing = require("busted.profile_using_flamegraph.timing")

--- Check if the profiler `event` is an auto-profiled function.
---
---@param event _ProfileEvent The event to check.
---@return boolean # If `event` was captured by the profiler or not.
---
function _P.is_function(event)
    return event.cat == "function"
end

--- Get the timing report for `events` + `threshold`.
---
---@param events _ProfileEvent[] All of the flamegraph data to consider.
---@param threshold number? A 1-or-more value. The "top slowest" functions to show.
---@return _ProfilerLine[] # The computed data (that will later become the report).
---
function _P.get_profile_report_lines(events, threshold)
    return timing.get_profile_report_lines(events, {
        predicate = function(_)
            return true
        end,
        threshold = threshold,
    })
end

--- Test using some `events` and make sure we get `expected`.
---
---@param events _ProfileEvent[] All of the flamegraph data to consider.
---@param expected _ProfilerLine[] # The computed data (that will later become the report).
---
function _P.run_simple_test(events, expected)
    assert.same(expected, _P.get_profile_report_lines(events, #expected))
end

-- TODO: Add tests for
--- checking multiple events at once
---    - starting array
---     - leaf
---    - middle array
---     - leaf
---    - ending array
---     - leaf
-- TODO: Need a test for if there are really small differences between numbers (floating precision issues)

describe("get_profile_report_as_text", function()
    describe("basic", function()
        it("sorts events correctly even if many small events sum up to be greater than single larger events", function()
            _P.run_simple_test({
                { cat = "function", dur = 1, name = "tiny_child_big_total_duration", tid = 1, ts = 0 },
                { cat = "function", dur = 3, name = "single_big_event", tid = 2, ts = 2 },
                { cat = "function", dur = 2, name = "tiny_child_big_total_duration", tid = 1, ts = 6 },
                { cat = "function", dur = 0.5, name = "tiny_subchild", tid = 1, ts = 7 },
                { cat = "function", dur = 2.5, name = "another_big_event", tid = 2, ts = 9 },
                { cat = "function", dur = 0.5, name = "tiny_child_big_total_duration", tid = 1, ts = 12 },
                { cat = "function", dur = 1, name = "tiny_child_big_total_duration", tid = 1, ts = 14 },
            }, {
                {
                    count = 4,
                    mean_time = "1.125",
                    median_time = "1.00",
                    name = "tiny_child_big_total_duration",
                    self_time = "4.00",
                    total_time = "4.50",
                },
            })
        end)

        it("#multiple duplicate events", function()
            local events = {
                { cat = "function", dur = 10, name = "multicall", tid = 1, ts = 1 },
                { cat = "function", dur = 2, name = "first_child", tid = 1, ts = 2 },
                { cat = "function", dur = 3, name = "multicall", tid = 1, ts = 11 },
                { cat = "function", dur = 1, name = "multicall", tid = 1, ts = 15 },
                { cat = "function", dur = 2.02, name = "another_event_that_is_past", tid = 1, ts = 20 },
            }
            _P.run_simple_test(events, {
                {
                    count = 3,
                    mean_time = "4.67",
                    median_time = "3.00",
                    name = "multicall",
                    self_time = "12.00",
                    total_time = "14.00",
                },
            })

            assert.equal(
                [[
───────────────────────────────────────────────
total-time                                17.02
───────────────────────────────────────────────
count total-time self-time name
───────────────────────────────────────────────
ttttttttttttttttt
]],
                timing.get_profile_report_as_text(events, { predicate = _P.is_function })
            )
        end)

        it("#simple events", function()
            local events = {
                { cat = "function", dur = 10, name = "outer_most", tid = 1, ts = 1 },
                { cat = "function", dur = 3, name = "first_child", tid = 1, ts = 2 },
                { cat = "function", dur = 2, name = "second_child", tid = 1, ts = 7 },
                { cat = "function", dur = 2.02, name = "another_event_that_is_past", tid = 1, ts = 11 },
            }
            _P.run_simple_test(events, {
                {
                    count = 1,
                    mean_time = "10.00",
                    median_time = "10.00",
                    name = "outer_most",
                    self_time = "5.00",
                    total_time = "10.00",
                },
            })
        end)

        it("works with #simple events", function()
            local events = {
                { cat = "function", dur = 6.13, name = "first_child", tid = 1, ts = 1 },
                { cat = "function", dur = 2.1561212333333, name = "second_child", tid = 1, ts = 8 },
                { cat = "function", dur = 2.02, name = "another_event_that_is_past", tid = 1, ts = 11 },
                { cat = "function", dur = 10.00, name = "outer_most", tid = 1, ts = 14 },
            }

            assert.equal(
                vim.fn.join({
                    "─────────────────────────────────────────────────────",
                    "total-time                                      20.31",
                    "─────────────────────────────────────────────────────",
                    "count total-time self-time name                      ",
                    "─────────────────────────────────────────────────────",
                    "1     10.00      10.00     outer_most                ",
                    "1     6.13       6.13      first_child               ",
                    "1     2.16       2.16      second_child              ",
                    "1     2.02       2.02      another_event_that_is_past",
                    "",
                }, "\n"),
                timing.get_profile_report_as_text(events, { predicate = _P.is_function })
            )
        end)

        it("works direct-children #direct", function()
            local events = {
                { cat = "function", dur = 10, name = "outer_most", tid = 1, ts = 1 },
                { cat = "function", dur = 3, name = "first_child", tid = 1, ts = 2 },
                { cat = "function", dur = 2, name = "second_child", tid = 1, ts = 7 },
                { cat = "function", dur = 2.02, name = "another_event_that_is_past", tid = 1, ts = 11 },
            }

            assert.equal(
                vim.fn.join({
                    "─────────────────────────────────────────────────────",
                    "total-time                                      17.02",
                    "─────────────────────────────────────────────────────",
                    "count total-time self-time name                      ",
                    "─────────────────────────────────────────────────────",
                    "1     10.00      5.00      outer_most                ",
                    "1     3.00       3.00      first_child               ",
                    "1     2.02       2.02      another_event_that_is_past",
                    "1     2.00       2.00      second_child              ",
                    "",
                }, "\n"),
                timing.get_profile_report_as_text(events, { predicate = _P.is_function })
            )
        end)
    end)

    describe("sections", function()
        it("re-orders sections as expected", function()
            local events = {
                { cat = "function", dur = 10, name = "outer_most", tid = 1, ts = 1 },
                { cat = "function", dur = 3, name = "first_child", tid = 1, ts = 2 },
                { cat = "function", dur = 2, name = "second_child", tid = 1, ts = 7 },
                { cat = "function", dur = 2.02, name = "another_event_that_is_past", tid = 1, ts = 11 },
            }

            assert.equal(
                vim.fn.join({
                    "───────────────────────────────────────────────",
                    "total-time                                17.02",
                    "───────────────────────────────────────────────",
                    "name                       total-time self-time",
                    "───────────────────────────────────────────────",
                    "outer_most                 10.00      5.00     ",
                    "first_child                3.00       3.00     ",
                    "another_event_that_is_past 2.02       2.02     ",
                    "second_child               2.00       2.00     ",
                    "",
                }, "\n"),
                timing.get_profile_report_as_text(events, {
                    predicate = _P.is_function,
                    sections = { "name", "total_time", "self_time" },
                })
            )
        end)

        it("use non-default sections", function()
            local events = {
                { cat = "function", dur = 5, name = "multicall", tid = 1, ts = 1 },
                { cat = "function", dur = 2, name = "first_child", tid = 1, ts = 2 },
                { cat = "function", dur = 3, name = "multicall", tid = 1, ts = 6 },
                { cat = "function", dur = 1, name = "multicall", tid = 1, ts = 10 },
                { cat = "function", dur = 2.02, name = "another_event_that_is_past", tid = 1, ts = 11 },
            }

            assert.equal(
                [[
──────────────────────────────────────
total-time                       17.02
──────────────────────────────────────
name                       median mean
──────────────────────────────────────
multicall                  10.00  5.00
another_event_that_is_past 2.02   2.02
first_child                2.00   2.00
]],
                timing.get_profile_report_as_text(events, {
                    predicate = _P.is_function,
                    sections = { "name", "median_time", "mean_time" },
                })
            )
        end)
    end)
end)

describe("self-time", function()
    it("works with a leaf-event that's at the end of the events stack #range", function()
        _P.run_simple_test({
            { cat = "function", dur = 6, name = "first_child", tid = 1, ts = 1 },
            { cat = "function", dur = 2, name = "second_child", tid = 1, ts = 8 },
            { cat = "function", dur = 2, name = "another_event_that_is_past", tid = 1, ts = 11 },
            { cat = "function", dur = 10, name = "outer_most", tid = 1, ts = 14 },
        }, {
            {
                count = 1,
                mean_time = "10.00",
                median_time = "10.00",
                name = "outer_most",
                self_time = "10.00",
                total_time = "10.00",
            },
        })
    end)

    it("works with different threads and unsorted event data #threads", function()
        _P.run_simple_test({
            { cat = "function", dur = 10, name = "outer_most", tid = 1, ts = 0 },
            { cat = "function", dur = 6, name = "other_thread", tid = 2, ts = 1 },
            { cat = "function", dur = 2, name = "first_child", tid = 1, ts = 4 },
            { cat = "function", dur = 2, name = "second_child", tid = 1, ts = 7 },
            { cat = "function", dur = 2, name = "another_event_that_is_past", tid = 1, ts = 11 },
        }, {
            {
                count = 1,
                mean_time = "10.00",
                median_time = "10.00",
                name = "outer_most",
                self_time = "6.00",
                total_time = "10.00",
            },
        })
    end)

    it("works with no results #empty", function()
        _P.run_simple_test({}, {})
    end)

    it("works with single event #single", function()
        _P.run_simple_test({
            { cat = "function", dur = 10, name = "outer_most", tid = 1, ts = 0 },
        }, {
            {
                count = 1,
                mean_time = "10.00",
                median_time = "10.00",
                name = "outer_most",
                self_time = "10.00",
                total_time = "10.00",
            },
        })
    end)

    it("works with only multiple direct children + multiple inner child per child #nested", function()
        -- TODO: Finish
    end)

    it("works with only multiple direct children #direct", function()
        _P.run_simple_test({
            { cat = "function", dur = 10, name = "outer_most", tid = 1, ts = 0 },
            { cat = "function", dur = 6, name = "first_child", tid = 1, ts = 1 },
            { cat = "function", dur = 2, name = "second_child", tid = 1, ts = 8 },
            { cat = "function", dur = 2, name = "another_event_that_is_past", tid = 1, ts = 11 },
        }, {
            {
                count = 1,
                mean_time = "10.00",
                median_time = "10.00",
                name = "outer_most",
                self_time = "2.00",
                total_time = "10.00",
            },
        })
    end)

    it("works with only one direct child #direct - 001", function()
        _P.run_simple_test({
            { cat = "function", dur = 10, name = "outer_most", tid = 1, ts = 0 },
            { cat = "function", dur = 6, name = "first_child", tid = 1, ts = 1 },
            { cat = "function", dur = 2, name = "another_event_that_is_past", tid = 1, ts = 11 },
        }, {
            {
                count = 1,
                mean_time = "10.00",
                median_time = "10.00",
                name = "outer_most",
                self_time = "4.00",
                total_time = "10.00",
            },
        })
    end)

    -- TODO: Finish this
    -- it("works with only one direct child #direct - 002", function()
    --     _P.run_simple_test({
    --         { cat = "function", dur = 10, name = "outer_most", tid = 1, ts = 0 },
    --         { cat = "function", dur = 6, name = "first_child", tid = 1, ts = 1 },
    --     }, { "1 10 4 outer_most" })
    -- end)

    it("works with only one direct child + one inner child", function()
        _P.run_simple_test({
            { cat = "function", dur = 10, name = "outer_most", tid = 1, ts = 0 },
            { cat = "function", dur = 6, name = "first_child", tid = 1, ts = 1 },
            { cat = "function", dur = 2, name = "inner_child", tid = 1, ts = 8 },
            { cat = "function", dur = 2, name = "another_event_that_is_past", tid = 1, ts = 11 },
        }, {
            {
                count = 1,
                mean_time = "10.00",
                median_time = "10.00",
                name = "outer_most",
                self_time = "2.00",
                total_time = "10.00",
            },
        })
    end)
end)
