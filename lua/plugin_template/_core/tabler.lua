--- Make dealing with Lua tables a bit easier.

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
