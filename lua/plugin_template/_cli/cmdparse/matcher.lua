-- TODO: Docstring

local constant = require("plugin_template._cli.cmdparse.constant")
local iterator_helper = require("plugin_template._cli.cmdparse.iterator_helper")
local texter = require("plugin_template._core.texter")

local M = {}

--- Create auto-complete text for `parameter`, given some `value`.
---
---@param parameter cmdparse.Parameter
---    A parameter that (we assume) takes exactly one value that we need
---    auto-completion options for.
---@param value string
---    The user-provided (exact or partial) value for the flag / named argument
---    value, if any. e.g. the `"bar"` part of `"--foo=bar"`.
---@param contexts cmdparse.ChoiceContext[]?
---    A description of how / when this function is called. It gets passed to
---    `cmdparse.Parameter.choices()`.
---@return string[]
---    All auto-complete values, if any.
---
local function _get_single_choices_text(parameter, value, contexts)
    if not parameter.choices then
        return { parameter.names[1] .. "=" }
    end

    contexts = contexts or {}

    local output = {}

    for _, choice in
        ipairs(parameter.choices({
            contexts = vim.list_extend({ constant.ChoiceContext.value_matching }, contexts),
            current_value = value,
        }))
    do
        table.insert(output, parameter.names[1] .. "=" .. choice)
    end

    return output
end

--- Check all `flags` that match `prefix` and `value`.
---
---@param prefix string
---    The name of the flag that must match, exactly or partially.
---@param flags cmdparse.Parameter[]
---    All position / flag / named parameters.
---@param value string?
---    The user-provided (exact or partial) value for the flag / named argument
---    value, if any. e.g. the `"bar"` part of `"--foo=bar"`.
---@param contexts cmdparse.ChoiceContext[]?
---    A description of how / when this function is called. It gets passed to
---    `cmdparse.Parameter.choices()`.
---@return cmdparse.Parameter[]
---    The matched parameters, if any.
---
function M.get_matching_partial_flag_text(prefix, flags, value, contexts)
    local output = {}

    for _, parameter in ipairs(iterator_helper.sort_parameters(flags)) do
        if not parameter:is_exhausted() then
            for _, name in ipairs(parameter.names) do
                if name == prefix then
                    if parameter:get_nargs() == 1 then
                        if not value then
                            table.insert(output, parameter.names[1] .. "=")
                        else
                            vim.list_extend(output, _get_single_choices_text(parameter, value, contexts))
                        end
                    else
                        table.insert(output, name)
                    end

                    break
                elseif vim.startswith(name, prefix) then
                    if parameter:get_nargs() == 1 then
                        table.insert(output, name .. "=")
                    else
                        table.insert(output, name)
                    end

                    break
                end
            end
        end
    end

    return output
end

--- Find all `options` that match `name`.
---
--- By default a position option takes any argument / value. Some position parameters
--- have specific, required choice(s) that this function means to match.
---
---@param name string
---    The user's input text to try to match.
---@param parameters cmdparse.Parameter[]
---    All position parameters to check.
---@param contexts cmdparse.ChoiceContext[]?
---    A description of how / when this function is called. It gets passed to
---    `cmdparse.Parameter.choices()`.
---@return cmdparse.Parameter[] # The found matches, if any.
---
function M.get_matching_position_parameters(name, parameters, contexts)
    contexts = contexts or {}
    local output = {}

    for _, parameter in ipairs(iterator_helper.sort_parameters(parameters)) do
        if not parameter:is_exhausted() and parameter.choices then
            vim.list_extend(
                output,
                texter.get_array_startswith(
                    parameter.choices({
                        contexts = vim.list_extend({ constant.ChoiceContext.position_matching }, contexts),
                        current_value = name,
                    }),
                    name
                )
            )
        end
    end

    return output
end

--- Find all all child parsers that start with `prefix`, starting from `parser`.
---
--- This function is **exclusive** - `parser` cannot be returned from this function.
---
---@param prefix string Some text to search for.
---@param parser cmdparse.ParameterParser The starting point to search within.
---@return string[] # The names of all matching child parsers.
---
function M.get_matching_subparser_names(prefix, parser)
    local output = {}

    for parser_ in iterator_helper.iter_parsers(parser) do
        local names = parser_:get_names()

        -- TODO: All current uses of this function ended up with `prefix` ==
        -- whitespace. If so, remove this if condition later
        if texter.is_whitespace(prefix) then
            vim.list_extend(output, names)
        else
            vim.list_extend(output, texter.get_array_startswith(names, prefix))
        end
    end

    return output
end

return M
