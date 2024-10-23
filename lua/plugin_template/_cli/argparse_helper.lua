--- Make dealing with COMMAND mode parsed arguments a bit easier.
---
---@module 'plugin_template._cli.argparse_helper'
---

local tabler = require("plugin_template._core.tabler")

local M = {}

--- Remove the starting `index` arguments from `results`.
---
--- This function is useful for handling "subcommand triage".
---
---@param results argparse.Results
---    The parsed arguments + any remainder text.
---@param index number
---    A 1-or-more value. 1 has not effect. 2-or-more will start removing
---    arguments from the left-hand side of `results`.
---
function M.lstrip_arguments(results, index)
    local copy = vim.tbl_deep_extend("force", {}, results)
    local arguments = tabler.get_slice(results.arguments, index)
    copy.arguments = arguments

    return copy
end

--- Remove the ending `index` arguments from `results`.
---
--- This function is useful for handling "subcommand triage".
---
---@param results argparse.Results
---    The parsed arguments + any remainder text.
---@param index number
---    A 1-or-more value. 1 has not effect. 2-or-more will remove arguments
---    from the right-hand side of `results`.
---@return argparse.Results
---    The stripped copy from `results`.
---
function M.rstrip_arguments(results, index)
    local copy = vim.tbl_deep_extend("force", {}, results)
    local arguments = tabler.get_slice(results.arguments, 1, index)
    copy.arguments = arguments

    return copy
end

return M
