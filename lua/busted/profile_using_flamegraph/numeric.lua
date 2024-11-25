-- TODO: Docstring

local M = {}

--- Find the exact middle value of all profile durations.
---
---@param values number[] All of the values to considered for the median.
---@return number # The found middle value.
---
function M.get_median(values)
    -- Sort the numbers in ascending order
    values = vim.fn.sort(values, function(left, right)
        return left > right
    end)
    local count = #values

    if count % 2 == 1 then
        return values[math.ceil(count / 2)]
    end

    local middle_left_index = count / 2
    local middle_right_index = middle_left_index + 1

    return (values[middle_left_index] + values[middle_right_index]) / 2
end

return M
