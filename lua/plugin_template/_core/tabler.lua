--- Make dealing with Lua tables a bit easier.
---
--- @module 'plugin_template._core.tabler'
---

local M = {}

--- Get a sub-section copy of `table_` as a new table.
---
--- @param table_ table<...>
---     A list / array / dictionary / sequence to copy + reduce.
--- @param first? number
---     The start index to use. This value is *inclusive* (the given index
---     will be returned). Uses `table_`'s first index if not provided.
--- @param last? number
---     The end index to use. This value is *inclusive* (the given index will
---     be returned). Uses every index to the end of `table_`' if not provided.
--- @param step? number
---     The step size between elements in the slice. Defaults to 1 if not provided.
---
function M.get_slice(table_, first, last, step)
    local sliced = {}

    for i = first or 1, last or #table_, step or 1 do
        sliced[#sliced + 1] = table_[i]
    end

    return sliced
end

function M.clear(data)
    -- Clear the table
    for index = #data, 1, -1 do
        table.remove(data, index)
    end
end

--- Append all of `items` to `table_`.
---
--- @param table_ ...[] Any values to add.
--- @param items ... The values to add.
---
function M.extend(table_, items)
    for _, item in ipairs(items) do
        table.insert(table_, item)
    end
end

return M
