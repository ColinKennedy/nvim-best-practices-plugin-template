--- Use flat flamegraph data to compute a function's self-time.
---
--- "Total-time" of a function is how long it took for a function to complete all of its work.
--- "Self-time" is different. It is constrained to 0-to-total-time and it is
--- "this function's execution time". So if a function calls another function,
--- that inner function is not part of the "self-time" of the outer function.
---
---@module 'busted.profile_using_flamegraph.self_timing'
---

local logging = require("plugin_template._vendors.aggro.logging")

local _LOGGER = logging.get_logger("busted.profile_using_flamegraph.self_timing")
local _P = {}
local M = {}

M.NOT_FOUND_INDEX = 1

--- Find all child events of `event`.
---
--- This does not include childs-of-childs of `event`.
---
---@param event _ProfileEvent The event to get children for.
---@param starting_index number The starting point to look for children. (Optimization).
---@param starting_indices table<number, number> All of the indices across all threads (Optimization).
---@param all_events _ProfileEvent[] All of the events to search for children.
---@param all_events_count number? The (precomputed) size of `all_events`.
---@return _ProfileEvent[] # The found children, if any.
---
function _P.get_direct_children(event, starting_index, starting_indices, all_events, all_events_count)
    all_events_count = all_events_count or #all_events
    local event_end_time = event.ts + event.dur

    ---@type _ProfileEvent[]
    local children = {}

    while starting_index < all_events_count and all_events[starting_index].ts < event_end_time do
        -- NOTE: Because we pre-sorted, we know that `reference_event` is
        -- a direct child of `event`.
        --
        -- We now need to scan for more children.
        --
        local reference_event = all_events[starting_index]
        local reference_event_end_time = reference_event.ts + reference_event.dur
        local reference_thread_id = reference_event.tid

        for index = starting_index + 1, all_events_count do
            local next_reference_event = all_events[index]

            if
                next_reference_event.tid == reference_thread_id
                and next_reference_event.ts > reference_event_end_time
            then
                -- NOTE: We've found the start of the next child. Which means
                -- every event index from the first `starting_index` to `index`
                -- is a direct child or nested child of `event`.
                --
                starting_indices[reference_event.tid] = index
                starting_index = index
                table.insert(children, reference_event)

                if next_reference_event.ts + next_reference_event.dur > event_end_time then
                    -- NOTE: We've reached the end. The next event is
                    -- completely outside of the original `event`.
                    --
                    return children
                end

                -- NOTE: We haven't reached the event's end yet. Keep looking for children.
                break
            end
        end
    end

    return children
end

--- Find the next index that is just after (but still within) `event`.
---
--- We use this later to find direct-children of the `event`.
---
---@param event _ProfileEvent The event to check for. We want the index **just after** this event.
---@param starting_index number The starting point to look for children. (Optimization).
---@param all_events _ProfileEvent[] All of the events to search for children.
---@param all_events_count number? The (precomputed) size of `all_events`.
---@return number -1 if not found but okay. 1-or-more if found.
---
function _P.get_next_starting_index(event, starting_index, all_events, all_events_count)
    all_events_count = all_events_count or #all_events
    local is_index_expected = false
    local found_index

    for index = starting_index, all_events_count do
        local reference_event = all_events[index]
        found_index = index

        if reference_event.tid == event.tid then
            if reference_event.ts > event.ts then
                return index
            end

            is_index_expected = true
        end
    end

    if not is_index_expected then
        return M.NOT_FOUND_INDEX
    end

    return found_index
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
---@param events _GroupedEvents[] All of the profiler event data to compute self-time for.
---@param all_events _ProfileEvent[] All reference profiler event data.
---@return table<string, number> # Each event name and its computed self-time.
---
function M.get_self_times(events, all_events)
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

    local all_events_count = #all_events

    for _, entry in ipairs(events) do
        --- Each thread ID and the index to start searching within `ranges`.
        ---@type table<number, number>
        ---
        local starting_indices = {}

        for _, event in
            ipairs(vim.fn.sort(entry.events, function(left, right)
                return left.ts > right.ts
            end))
        do
            ---@cast event _ProfileEvent

            local starting_index =
                _P.get_next_starting_index(event, (starting_indices[event.tid] or 1), all_events, all_events_count)

            if starting_index == M.NOT_FOUND_INDEX then
                -- NOTE: If we're on the very last event and there are no other events then it means
                -- 1. We're on the very last call that was profiled.
                -- 2. That last function is also a leaf function (it doesn't call anything else).
                --
                -- This should be a really rare occurrence. But could happen.
                --
                _LOGGER:fmt_info(
                    'We think "%s" event is the last of its kind'
                        .. " (last event in thread + calls no other functions) "
                        .. " so we are using its full duration as its self-time.",
                    event
                )

                output[event.name] = event.dur

                break
            end

            local other_time = 0

            for _, child in
                ipairs(_P.get_direct_children(event, starting_index, starting_indices, all_events, all_events_count))
            do
                other_time = other_time + child.dur
            end

            output[event.name] = (output[event.name] or 0) + event.dur - other_time
        end
    end

    return output
end

return M
