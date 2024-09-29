-- TODO: Docstring
local M = {}

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
function M.iter_parsers(parser, inclusive)
    -- TODO: Audit this variable. Maybe remove / make default
    if inclusive == nil then
        inclusive = false
    end

    local subparsers_index = 1
    local subparsers = parser._subparsers[subparsers_index]
    local returned_parser = false

    -- TODO: Remove?
    -- if not subparsers then
    --     if inclusive then
    --         return function() return nil end
    --     end
    --
    --     return function()
    --         if not returned_parser then
    --             returned_parser = true
    --
    --             return parser
    --         end
    --
    --         return nil
    --     end
    -- end

    local parser_index = 1
    local parsers = {}

    if subparsers then
        parsers = subparsers:get_parsers()
    end

    local parser_count = #parsers

    return function()
        if inclusive and not returned_parser then
            return parser
        end

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

return M
