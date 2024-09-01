--- Functions that fill-in missing values, validate values, etc for cmdparse types.
---
---@module 'plugin_template._cli.cmdparse.types_input'
---

local constant = require("plugin_template._cli.cmdparse.constant")
local text_parse = require("plugin_template._cli.cmdparse.text_parse")
local texter = require("plugin_template._core.texter")

local M = {}

local _FLAG_ACTIONS = { constant.Action.count, constant.Action.store_false, constant.Action.store_true }

--- Print `data` but don't recurse.
---
--- If you don't call this function when you try to print one of our Parameter
--- types, it will print parent / child objects and it ends up printing the
--- whole tree. This function instead prints just the relevant details.
---
---@param data any Anything. Usually an Parameter type from this file.
---@return string # The found data.
---
local function _concise_inspect(data)
    --- NOTE: Not sure why llscheck doesn't like this line. Maybe the
    --- annotations for `vim.inspect` are incorret.
    ---
    ---@diagnostic disable-next-line redundant-parameter
    return vim.inspect(data, { depth = 1 }) or ""
end

--- Find a proper type converter from `options`.
---
---@param options cmdparse.ParameterInputOptions | cmdparse.ParameterOptions The suggested type for an parameter.
---
local function _expand_type_options(options)
    if not options.type then
        options.type = function(value)
            return value
        end
    elseif options.type == "string" then
        options.type = function(value)
            return value
        end
    elseif options.type == "number" then
        options.type = function(value)
            return tonumber(value)
        end
    elseif type(options.type) == "function" then
        -- NOTE: Do nothing. Assume the user knows what they're doing.
        return
    else
        error(string.format('Type "%s" is unknown. We can\'t parse it.', _concise_inspect(options)), 0)
    end
end

--- Add / modify `options.choices` as needed.
---
--- Basically if `options.choices` is not defined, that's fine. If it is
--- a `string` or `string[]`, handle that. If it's a function, assume the user
--- knows what they're doing and include it.
---
---@param options cmdparse.ParameterInputOptions
---    | cmdparse.ParameterOptions
---    | cmdparse.ParameterParserOptions
---    | cmdparse.ParameterParserInputOptions
---    The user-written options. (sparse or not).
---
function M.expand_choices_options(options)
    if not options.choices then
        return
    end

    local input = options.choices
    local choices

    if type(options.choices) == "string" then
        choices = function()
            return { input }
        end
    elseif texter.is_string_list(input) then
        ---@cast input string[]
        choices = function(data)
            ---@cast data cmdparse.ChoiceData

            if not data or not data.current_value then
                return input
            end

            local value = data.current_value
            ---@cast value string | string[]

            if vim.tbl_contains(data.contexts, constant.ChoiceContext.auto_completing) then
                ---@cast value string
                return texter.get_array_startswith(input, value)
            end

            return input
        end
    elseif type(options.choices) == "function" then
        choices = input
    else
        error(
            string.format( -- NOTE: choices has to be a known format.
                'Got invalid "%s" choices. Expected a string[] or a function.',
                _concise_inspect(options.choices)
            ),
            0
        )
    end

    options.choices = choices
end

--- Make sure an `cmdparse.Parameter` has a name and every name is the same type.
---
--- If `names` is `{"foo", "-f"}` then this function will error.
---
---@param options cmdparse.ParameterInputOptions | cmdparse.ParameterOptions All data to check.
---
function M.expand_parameter_names(options)
    local function _get_type(name)
        if text_parse.is_position_name(name) then
            return "position"
        end

        return "flag"
    end

    local names = options.names or options.name or options[1]

    if type(names) == "string" then
        names = { names }
    end

    if not names then
        error(string.format('Options "%s" is missing a "name" key.', vim.inspect(options)), 0)
    end

    local found_type = nil

    for _, name in ipairs(names) do
        if not found_type then
            found_type = _get_type(name)
        elseif found_type ~= _get_type(name) then
            error(
                string.format(
                    "Parameter names have to be the same type. "
                        .. 'e.g. If one name starts with "-", all names '
                        .. 'must start with "-" and vice versa.'
                ),
                0
            )
        end
    end

    if not found_type then
        error(string.format('Options "%s" must provide at least one name.', vim.inspect(names)), 0)
    end

    options.names = names
end

--- If `options` is sparsely written, "expand" all of its values. so we can use it.
---
---@param options cmdparse.ParameterInputOptions | cmdparse.ParameterOptions
---    The user-written options. (sparse or not).
---@param is_position boolean
---    If `options` is meant to be a non-flag argument. e.g. `--foo` is `false`.
---
function M.expand_parameter_options(options, is_position)
    _expand_type_options(options)
    M.expand_choices_options(options)

    if options.required == nil then
        if is_position then
            options.required = options.count ~= constant.Counter.zero_or_more
        else
            options.required = false
        end
    end

    if vim.tbl_contains(_FLAG_ACTIONS, options.action) and not options.nargs then
        options.nargs = 0
    end

    if not options.nargs then
        options.nargs = 1
    end

    if options.required == nil then
        if is_position then
            options.required = true
        else
            options.required = false
        end
    end
end

--- Make sure `options` has no conflicting / missing data.
---
--- Raises:
---     If an issue is found.
---
---@param options cmdparse.ParameterInputOptions | cmdparse.ParameterOptions
---    All data to check.
---
function M.validate_parameter_options(options)
    local is_position = text_parse.is_position_name(options.names[1])

    if is_position then
        if vim.tbl_contains(_FLAG_ACTIONS, options.action) then
            error(string.format('Parameter "%s" cannot use action="%s".', options.names[1], options.action), 0)
        end

        if options.nargs == 0 then
            error(string.format('Parameter "%s" cannot be nargs=0.', options.names[1]), 0)
        end
    end

    if type(options.nargs) == "number" and options.nargs < 0 then
        error(string.format('Nargs "%s" cannot be less than zero.', options.nargs), 0)
    end

    if vim.tbl_contains(_FLAG_ACTIONS, options.action) then
        if options.choices ~= nil then
            error(
                string.format(
                    'Parameter "%s" cannot use action "%s" and choices at the same time.',
                    options.names[1],
                    options.action
                ),
                0
            )
        end

        if options.nargs ~= 0 then
            error(
                string.format(
                    'Parameter "%s" cannot use action "%s" and nargs at the same time.',
                    options.names[1],
                    options.action
                ),
                0
            )
        end
    end
end

--- Make sure a name was provided from `options`.
---
---@param options cmdparse.ParameterParserOptions
---
function M.validate_name(options)
    if not options.name or texter.is_whitespace(options.name) then
        error(string.format('Parameter "%s" must have a name.', _concise_inspect(options)), 0)
    end
end

return M
