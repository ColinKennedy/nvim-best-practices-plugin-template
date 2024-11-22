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
    it("works with basic events", function()
        local events = {
            { cat = "function", dur = 6.13, name = "first_child", tid = 1, ts = 1 },
            { cat = "function", dur = 2.1561212333333, name = "second_child", tid = 1, ts = 8 },
            { cat = "function", dur = 2.02, name = "another_event_that_is_past", tid = 1, ts = 11 },
            { cat = "function", dur = 10.00, name = "outer_most", tid = 1, ts = 14 },
        }

        assert.equal(
            [[
────────────────────────────────────────────────────────────────
total-time                                                 20.31
────────────────────────────────────────────────────────────────
count total-time      self-time       name
────────────────────────────────────────────────────────────────
1     10              10              outer_most
1     6.13            6.13            first_child
1     2.1561212333333 2.1561212333333 second_child
1     2.02            2.02            another_event_that_is_past
]],
            timing.get_profile_report_as_text(events, { predicate = _P.is_function })
        )
    end)

    it("works direct-children #direct #asdf", function()
        local events = {
            { cat = "function", dur = 10, name = "outer_most", tid = 1, ts = 1 },
            { cat = "function", dur = 3, name = "first_child", tid = 1, ts = 2 },
            { cat = "function", dur = 2, name = "second_child", tid = 1, ts = 7 },
            { cat = "function", dur = 2.02, name = "another_event_that_is_past", tid = 1, ts = 11 },
        }

        assert.equal(
            [[
─────────────────────────────────────────────────────
total-time                                      17.02
─────────────────────────────────────────────────────
count total-time self-time name                      
─────────────────────────────────────────────────────
1     10         10        outer_most                
1     3          3         first_child               
1     2.02       2.02      another_event_that_is_past
1     2          2         second_child              
]],
            timing.get_profile_report_as_text(events, { predicate = _P.is_function })
        )
    end)
end)

describe("self-time", function()
    it("works with a leaf-event that's at the end of the events stack #range", function()
        _P.run_simple_test({
            { cat = "function", dur = 6, name = "first_child", tid = 1, ts = 1 },
            { cat = "function", dur = 2, name = "second_child", tid = 1, ts = 8 },
            { cat = "function", dur = 2, name = "another_event_that_is_past", tid = 1, ts = 11 },
            { cat = "function", dur = 10, name = "outer_most", tid = 1, ts = 14 },
        }, { { count = 1, name = "outer_most", self_time = 10, total_time = 10 } })
    end)

    it("works with different threads and unsorted event data #threads", function()
        _P.run_simple_test({
            { cat = "function", dur = 10, name = "outer_most", tid = 1, ts = 0 },
            { cat = "function", dur = 6, name = "other_thread", tid = 2, ts = 1 },
            { cat = "function", dur = 2, name = "first_child", tid = 1, ts = 4 },
            { cat = "function", dur = 2, name = "second_child", tid = 1, ts = 7 },
            { cat = "function", dur = 2, name = "another_event_that_is_past", tid = 1, ts = 11 },
        }, { { count = 1, name = "outer_most", self_time = 6, total_time = 10 } })
    end)

    it("works with no results #empty", function()
        _P.run_simple_test({}, {})
    end)

    it("works with single event #single", function()
        _P.run_simple_test({
            { cat = "function", dur = 10, name = "outer_most", tid = 1, ts = 0 },
        }, { { count = 1, name = "10 outer_most", self_time = 10, total_time = 10 } })
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
        }, { { count = 1, name = "outer_most", self_time = 2, total_time = 10 } })
    end)

    it("works with only one direct child #direct - 001", function()
        _P.run_simple_test({
            { cat = "function", dur = 10, name = "outer_most", tid = 1, ts = 0 },
            { cat = "function", dur = 6, name = "first_child", tid = 1, ts = 1 },
            { cat = "function", dur = 2, name = "another_event_that_is_past", tid = 1, ts = 11 },
        }, { { count = 1, name = "outer_most", self_time = 4, total_time = 10 } })
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
            { cat = "function", dur = 2, name = "inner_child", tid = 1, ts = 3 },
            { cat = "function", dur = 2, name = "another_event_that_is_past", tid = 1, ts = 11 },
        }, { { count = 1, name = "outer_most", self_time = 8, total_time = 10 } })
    end)
end)
