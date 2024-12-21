-- TODO: Docstring

-- TODO: Finish the tests here

local timing = require("busted.profile_using_flamegraph.timing")

local _get_profile_report_lines = function(events, threshold)
    return timing.get_profile_report_lines(events, threshold, function(_) return true end)
end

local function _run_simple_test(events, expected, threshold)
    assert.same(expected, _get_profile_report_lines(events, threshold or #expected))
end

-- TODO: Need a test for if there are really small differences between numbers (floating precision issues)

-- TODO: Remove tag
describe("self-time #asdf", function()
    it("works with a leaf-event that's at the end of the events stack #range", function()
        _run_simple_test(
            {
                { cat="function", dur=6, name="first_child", tid=1, ts=1 },
                { cat="function", dur=2, name="second_child", tid=1, ts=8 },
                { cat="function", dur=2, name="another_event_that_is_past", tid=1, ts=11 },
                { cat="function", dur=10, name="outer_most", tid=1, ts=14 },
            },
            {"1 10 10 outer_most"}
        )
    end)

    it("works with different threads and unsorted event data #threads", function()
        -- TODO: Finish
    end)

    it("works with no results #empty", function()
        _run_simple_test({}, {})
    end)

    it("works with single event #single", function()
        _run_simple_test(
            {
                { cat="function", dur=10, name="outer_most", tid=1, ts=0 },
            },
            {"1 10 10 outer_most"}
        )
    end)

    it("works with only multiple direct children + multiple inner child per child #nested", function()
        -- TODO: Finish
    end)

    it("works with only multiple direct children #direct", function()
        _run_simple_test(
            {
                { cat="function", dur=10, name="outer_most", tid=1, ts=0 },
                { cat="function", dur=6, name="first_child", tid=1, ts=1 },
                { cat="function", dur=2, name="second_child", tid=1, ts=8 },
                { cat="function", dur=2, name="another_event_that_is_past", tid=1, ts=11 },
            },
            {"1 10 2 outer_most"}
        )
    end)

    it("works with only one direct child #direct", function()
        _run_simple_test(
            {
                { cat="function", dur=10, name="outer_most", tid=1, ts=0 },
                { cat="function", dur=6, name="first_child", tid=1, ts=1 },
                { cat="function", dur=2, name="another_event_that_is_past", tid=1, ts=11 },
            },
            {"1 10 4 outer_most"}
        )

        -- TODO: Move?
        -- _run_simple_test(
        --     {
        --         { cat="function", dur=10, name="outer_most", tid=1, ts=0 },
        --         { cat="function", dur=6, name="first_child", tid=1, ts=1 },
        --     },
        --     {"1 10 4 outer_most"}
        -- )
    end)

    it("works with only one direct child + one inner child", function()
        _run_simple_test(
            {
                { cat="function", dur=10, name="outer_most", tid=1, ts=0 },
                { cat="function", dur=6, name="first_child", tid=1, ts=1 },
                { cat="function", dur=2, name="inner_child", tid=1, ts=3 },
                { cat="function", dur=2, name="another_event_that_is_past", tid=1, ts=11 },
            },
            {"1 10 4 outer_most"}
        )
    end)
end)
