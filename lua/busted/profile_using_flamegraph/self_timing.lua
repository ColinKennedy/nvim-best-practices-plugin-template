-- TODO: Docstring

local M = {}


M.NOT_FOUND_INDEX = 1


-- TODO: Docstring
---
--- Raises:
---     If we expected an index but could not found one.
---
---@param event _ProfileEvent
---@param starting_index number
---@param all_events _ProfileEvent[]
---@param all_events_count number?
---@return number -1 if not found but okay. 1-or-more if good
function M.get_next_starting_index(event, starting_index, all_events, all_events_count)
    all_events_count = all_events_count or #all_events
    local is_index_expected = false
    local found_index

    for index=starting_index, all_events_count do
        local reference_event = all_events[index]
        found_index = index

        if reference_event.tid == event.tid then
            -- TODO: Consider rounding errors here
            if reference_event.ts > event.ts then
                return index
            end

            is_index_expected = true
        end
    end

    if not is_index_expected then
        return M.NOT_FOUND_INDEX
    end

    error(
        string.format(
            'Bug: We should have found an index but didn\'t. '
            .. 'We started at "%s" index and ran to "%s" but stopped short at "%s".',
            starting_index,
            all_events_count,
            found_index
        ),
        0
    )
end

return M
