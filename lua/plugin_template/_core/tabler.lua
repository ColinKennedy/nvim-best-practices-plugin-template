--- Make dealing with Lua tables a bit easier.
---
---@module 'plugin_template._core.tabler'
---

local M = {}

--- Get a sub-section copy of `table_` as a new table.
---
---@param table_ table<any, any>
---    A list / array / dictionary / sequence to copy + reduce.
---@param first? number
---    The start index to use. This value is **inclusive** (the given index
---    will be returned). Uses `table_`'s first index if not provided.
---@param last? number
---    The end index to use. This value is **inclusive** (the given index will
---    be returned). Uses every index to the end of `table_`' if not provided.
---@param step? number
---    The step size between elements in the slice. Defaults to 1 if not provided.
---@return table<any, any>
---    The subset of `table_`.
---
function M.get_slice(table_, first, last, step)
    local sliced = {}

    for i = first or 1, last or #table_, step or 1 do
        sliced[#sliced + 1] = table_[i]
    end

    return sliced
end

--- Access the attribute(s) within `data` from `items`.
---
---@param data any Some nested data to query. e.g. `{a={b={c=true}}}`.
---@param items string[] Some attributes to query. e.g. `{"a", "b", "c"}`.
---@return any? # The found value, if any.
---
function M.get_value(data, items)
    local current = data
    local found = {}
    local count = #items

    for index = 1, count do
        local item = items[index]
        current = current[item]

        if current == nil then
            return nil
        end

        table.insert(found, item)

        local type_ = type(current)

        if index < count and type_ ~= "table" then
            error(string.format("%s: expected table, got %s", vim.fn.join(found, "."), type_), 0)
        end
    end

    return current
end

--- Iterate over all of the given arrays.
---
---@param ... table<any, any>[] All of the tables to expand
---@return any # Every element of each table, in order.
---
function M.chain(...)
    local lists = { ... }
    local index = 0
    local current = 1

    return function()
        while current <= #lists do
            index = index + 1

            if index <= #lists[current] then
                return lists[current][index]
            else
                -- Move to the next list
                index = 0
                current = current + 1
            end
        end
    end
end

--- Delete the contents of `data`.
---
---@param data table<any, any> A dictionary or array to clear.
---
function M.clear(data)
    -- Clear the table
    for index = #data, 1, -1 do
        table.remove(data, index)
    end
end

--- Append all of `items` to `table_`.
---
---@param table_ any[] Any values to add.
---@param items any The values to add.
---
function M.extend(table_, items)
    for _, item in ipairs(items) do
        table.insert(table_, item)
    end
end

--- Create a copy of `array` with its items in reverse order.
---
---@param array table<any, any> Some (non-dictionary) items e.g. `{"a", "b", "c"}`.
---@return table<any, any> # The reversed items e.g. `{"c", "b", "a"}`.
---
function M.reverse_array(array)
    local output = {}

    for index = #array, 1, -1 do
        table.insert(output, array[index])
    end

    return output
end

return M
