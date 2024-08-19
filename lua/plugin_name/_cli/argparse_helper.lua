--- Make dealing with COMMAND mode parsed arguments a bit easier.
---
--- @module 'plugin_name._cli.argparse_helper'
---

local tabler = require("plugin_name._core.tabler")

local M = {}

--- Remove the starting `index` arguments from `results`.
---
--- This function is useful for handling "subcommand triage".
---
--- @param results ArgparseResults The parsed arguments + any remainder text.
--- @param index number
---     A 1-or-more value. 1 has not effect. 2-or-more will start removing arguments from the left-hand side of `results`.
---
function M.lstrip_arguments(results, index)
    local copy = vim.tbl_deep_extend("force", {}, results)
    local arguments = tabler.get_slice(results.arguments, index)
    copy.arguments = arguments

    return copy
end

return M

