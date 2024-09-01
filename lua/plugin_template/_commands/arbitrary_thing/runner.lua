--- The main file that implements `arbitrary-thing` outside of COMMAND mode.
---
---@module 'plugin_template._commands.arbitrary_thing.runner'
---

local M = {}

--- Print the `names`.
---
---@param names string[]? Some text to print out. e.g. `{"a", "b", "c"}`.
---
function M.run(names)
    local text

    if not names or vim.tbl_isempty(names) then
        text = "<No text given>"
    else
        text = vim.fn.join(names, ", ")
    end

    vim.notify(text, vim.log.levels.INFO)
end

return M
