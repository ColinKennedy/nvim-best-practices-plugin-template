-- TODO: Docstring
local tabler = require("plugin_name._core.tabler")

local M = {}

function M.lstrip_arguments(results, index)
    local copy = vim.tbl_deep_extend("force", {}, results)
    local arguments = tabler.get_slice(results.arguments, index)
    copy.arguments = arguments

    return copy
end

return M

