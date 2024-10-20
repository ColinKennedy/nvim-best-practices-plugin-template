--- Generic functions used in other files.
---
---@module 'plugin_template._cli.cmdparse.iterator_helper'
---

local M = {}

local _FULL_HELP_FLAG = "--help"
local _SHORT_HELP_FLAG = "-h"

--- Find all direct-children parsers of `parser`.
---
--- Note:
---    This is not recursive. It just gets the direct children.
---
---@param parser cmdparse.ParameterParser
---    The starting point ot saerch for child parsers.
---@param inclusive boolean?
---    If `true`, `parser` will be the first returned value. If `false` then
---    only the children are returned.
---@return fun(): cmdparse.ParameterParser?
---    An iterator that find all child parsers.
---
function M.iter_parsers(parser)
    local subparsers_index = 1
    local subparsers = parser._subparsers[subparsers_index]

    local parser_index = 1
    local parsers = {}

    if subparsers then
        parsers = subparsers:get_parsers()
    end

    local parser_count = #parsers

    return function()
        if parser_index > parser_count then
            -- NOTE: Get the next subparsers.
            parser_index = 1
            subparsers_index = subparsers_index + 1
            parsers = parser._subparsers[subparsers_index]

            if not parsers then
                -- NOTE: We reached the end.
                return nil
            end

            return parsers[parser_index]
        end

        local result = parsers[parser_index]

        parser_index = parser_index + 1

        return result
    end
end

--- Re-order `parameters` alphabetically but put the `--help` flag at the end.
---
---@param parameters cmdparse.Parameter[] All position / flag / named parameters.
---@return cmdparse.Parameter[] # The sorted entries.
---
function M.sort_parameters(parameters)
    local output = vim.deepcopy(parameters)

    table.sort(output, function(left, right)
        if vim.tbl_contains(left.names, _FULL_HELP_FLAG) or vim.tbl_contains(left.names, _SHORT_HELP_FLAG) then
            return false
        end

        if vim.tbl_contains(right.names, _FULL_HELP_FLAG) or vim.tbl_contains(right.names, _SHORT_HELP_FLAG) then
            return true
        end

        return left.names[1] < right.names[1]
    end)

    return output
end

return M
