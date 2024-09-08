-- TODO: Docstring
-- TODO: Clean-up code

-- TODO: Add unittest for required subparsers
 - set_required must fail if subparsers has no dest

local argparse = require("plugin_template._cli.argparse")
local argparse_helper = require("plugin_template._cli.argparse_helper")
local tabler = require("plugin_template._core.tabler")

--- @class ArgumentTypeOption
---     When an argument value is found it is converted to `type`
--- @field type ("number" | "string" | fun(value: string): ...)?
---     The expected output type. If a function is given, assume that the user
---     knows what they're doing and use their function's return value.

local M = {}

-- TODO: Add support for this later
local _ONE_OR_MORE = "__one_or_more"
local _ZERO_OR_MORE = "__zero_or_more"

M.Argument = {
    __tostring = function(argument)
        return string.format(
            'Argument({names=%s, help=%s, type=%s, action=%s, nargs=%s})',
            vim.inspect(argument.names),
            vim.inspect(argument.help),
            vim.inspect(argument.type),
            vim.inspect(argument._action),
            vim.inspect(argument._nargs)
        )
    end,
}
M.Argument.__index = M.Argument

M.ArgumentParser = {
    __tostring = function(parser)
        return string.format('ArgumentParser({description="%s"})', parser.description)
    end,
}
M.ArgumentParser.__index = M.ArgumentParser

M.Subparsers = {
    __tostring = function(subparsers)
        return string.format(
            'Subparsers({description="%s", destination="%s"})',
            subparsers.description,
            subparsers.destination
        )
    end,
}
M.Subparsers.__index = M.Subparsers


local function _is_position_name(text)
    return text:sub(1, 1):match("%w")
end


local function _is_whitespace(text)
    return text:match("%s+")
end


local function _get_argument_name(argument)
    return argument.name or argument.value
end


-- local function _get_matches(name, items)
--     local output = {}
--
--     for _, item in ipairs(items) do
--         for _, item_name in ipairs(item.names) do
--             if item_name == name then
--                 table.insert(output, item)
--
--                 break
--             end
--         end
--     end
--
--     return output
-- end


local function _get_nice_name(text)
    return text:match("%W*(%w+)")
end

--- Find a proper type converter from `options`.
---
--- @param options ArgumentTypeOption The suggested type for an argument.
--- @return ArgumentTypeOption # An "expanded" variant of the orginal `options`.
---
local function _expand_type_options(options)
    options = vim.deepcopy(options)

    -- TODO: Make unittests for this
    if not options.type then
        options.type = function(value) return value end
    elseif options.type == "string" then
        options.type = function(value) return value end
    elseif options.type == "number" then
        options.type = function(value) return tonumber(value) end
    elseif type(options.type) == "function" then
        -- NOTE: Do nothing. Assume the user knows what they're doing
    else
        error(string.format('Type "%s" is unknown. We can\'t parse it.', vim.inspect(options)))
    end

    return options
end


-- TODO: Add unittest for this
local function _validate_argument_names(names)
    local function _get_type(name)
        if _is_position_name(name) then
            return "position"
        end

        return "flag"
    end

    local found_type = nil

    for _, name in ipairs(names) do
        if not found_type then
            found_type = _get_type(name)
        elseif found_type ~= _get_type(name) then
            error(
                string.format(
                    'Argument names have to be the same type. '
                    .. 'e.g. If one name starts with "-", all names '
                    .. 'must start with "-" and vice versa.'
                )
            )
        end
    end
end


local function _validate_name(options)
    -- TODO: name is required
    if not options.name or _is_whitespace(options.name) then
        error(string.format('Argument "%s" must have a name.', vim.inspect(options)))
    end
end


function M.Subparsers.new(options)
    local self = setmetatable({}, M.Subparsers)

    self.description = options.description
    self.destination = options.destination
    self._parsers = {}

    return self
end


function M.Subparsers:add_parser(options)
    local new_options = vim.tbl_deep_extend("force", options, {parent = self})
    local parser = M.ArgumentParser.new(new_options)

    table.insert(self._parsers, parser)

    return parser
end


function M.Subparsers:get_parsers()
    return self._parsers
end


function M.Argument.new(options)
    if not options.names or vim.tbl_isempty(options.names) then
        error(string.format('Argument "%s" must define `names`.', vim.inspect(options)))
    end

    _validate_argument_names(options.names)
    options = _expand_type_options(options)

    local self = setmetatable({}, M.Argument)

    self._action = nil
    self._type = options.type
    self._count = 1
    self._used = 0
    self.destination = options.destination
    self.names = options.names
    self:set_action(options.action)

    return self
end


function M.Argument:is_exhausted()
    return self._used >= self._count
end


function M.Argument:get_action()
    return self._action
end


function M.Argument:get_nice_name()
    return _get_nice_name(self.destination or self.names[1])
end


function M.Argument:get_type()
    return self._type
end


function M.Argument:increment_used(increment)
    increment = increment or 1
    self._used = self._used + increment
end


function M.Argument:set_action(action)
    if action == "store_false" then
        action = function(data)
            data.namespace[data.name] = false
        end
    elseif action == "store_true" then
        action = function(data)
            data.namespace[data.name] = true
        end
    elseif action == "count" then
        action = function(data)
            local name = data.name
            local namespace = data.namespace

            if not namespace[name] then
                namespace[name] = 0
            end

            namespace[name] = namespace[name] + 1
        end
    elseif action == "append" then
        action = function(data)
            local name = data.name
            local namespace = data.namespace

            if not namespace[name] then
                namespace[name] = {}
            end

            table.insert(namespace[name], data.value)
        end
    else
        action = function(data)
            data.namespace[data.name] = data.value
        end
    end

    self._action = action
end


function M.Argument:set_nargs(count)
    local self = setmetatable({}, M.Argument)

    if count == "*" then
        count = _ZERO_OR_MORE
    elseif count == "+" then
        count = _ONE_OR_MORE
    end

    self._nargs = count
end


function M.ArgumentParser.new(options)
    if options.parent then
        _validate_name(options)
    end

    local self = setmetatable({}, M.ArgumentParser)

    self.name = options.name
    self.description = options.description
    self._position_arguments = {}
    self._flag_arguments = {}
    self._subparsers = {}

    return self
end


function M.ArgumentParser:_get_default_namespace()
    local output = {}

    -- TODO: Add unittests for these arg types
    for argument in tabler.chain(self._position_arguments, self._flag_arguments) do
        if argument.default then
            output[argument:get_nice_name()] = argument.default
        end
    end

    return output
end


function M.ArgumentParser._get_usage_summary()
    -- TODO: Need to finish the concise args and also give advice on the next line
    return "usage: TODO"
end


function M.ArgumentParser:_handle_flag_arguments(flag_arguments, argument, namespace)
    for _, flag in ipairs(flag_arguments) do
        if not flag:is_exhausted() then
            local name = flag:get_nice_name()
            local value = flag:get_type()(argument.value)
            local action = flag:get_action()

            action({namespace=namespace, name=name, value=value})

            flag:increment_used()

            return true
        end
    end

    return false
end


function M.ArgumentParser:_handle_position_arguments(argument, positions, namespace)
    for _, position in ipairs(positions) do
        if not position:is_exhausted() then
            local name = position:get_nice_name()
            local value = position:get_type()(argument.value)
            local action = position:get_action()

            action({namespace=namespace, name=name, value=value})

            position:increment_used()

            return true
        end
    end

    return false
end


function M.ArgumentParser:_handle_subparsers(data, argument_name, index, namespace)
    for _, subparser in ipairs(self._subparsers) do
        for _, parser in ipairs(subparser:get_parsers()) do
            if parser.name == argument_name then
                parser:parse_arguments(
                    argparse_helper.lstrip_arguments(data, index), namespace
                )

                return true
            end
        end
    end

    return false
end


function M.ArgumentParser:get_concise_help()
    -- TODO: Need to finish the concise args and also give advice on the next line
    return M.ArgumentParser._get_usage_summary()
end


function M.ArgumentParser:get_full_help()
    local summary = M.ArgumentParser._get_usage_summary()

    return string.format("%s\n\noptions:%s", summary, "TODO")
end


function M.ArgumentParser:add_argument(options)
    local names = options.names

    if type(names) == "string" then
        names = {names}
    end

    local new_options = vim.tbl_deep_extend("force", options, ({names=names}))
    local argument = M.Argument.new(new_options)
    argument.parent = self

    if _is_position_name(names[1]) then
        table.insert(self._position_arguments, argument)
    else
        table.insert(self._flag_arguments, argument)
    end

    return argument

end


function M.ArgumentParser:add_subparsers(options)
    local new_options = vim.tbl_deep_extend("force", options, {parent = self})
    local subparsers = M.Subparsers.new(new_options)

    table.insert(self._subparsers, subparsers)

    return subparsers
end


-- function M.ArgumentParser:_get_matches(argument)
--     if argument.argument_type == argparse.ArgumentType.position then
--         local output = {}
--         local name = _get_argument_name(argument)
--
--         for _, subparser in ipairs(self._subparsers) do
--             for _, parser in ipairs(subparser:get_parsers()) do
--                 if parser.name == name then
--                     -- TODO: Finish
--                     print("ASDASD")
--                 end
--             end
--         end
--
--         local positions = self:_get_position_arguments()
--
--         for _, position in ipairs(positions) do
--         end
--
--         return output
--     end
--
--     return {}
-- end


-- function M.ArgumentParser:_get_position_arguments()
--     local output = {}
--
--     for _, argument in ipairs(self._position_arguments) do
--         if argument.argument_type == argparse.ArgumentType.position then
--             table.insert(output, argument)
--         end
--     end
--
--     return output
-- end


function M.ArgumentParser:parse_arguments(data, namespace)
    if type(data) == "string" then
        data = argparse.parse_arguments(data)
    end

    namespace = namespace or self:_get_default_namespace()

    local position_arguments = vim.deepcopy(self._position_arguments)
    local flag_arguments = vim.deepcopy(self._flag_arguments)

    for index, argument in ipairs(data.arguments) do
        if argument.argument_type == argparse.ArgumentType.position then
            local argument_name = _get_argument_name(argument)

            local found = self:_handle_subparsers(data, argument_name, index + 1, namespace)

            if not found then
                -- print('DEBUGPRINT[65]: argparse2.lua:472: position_arguments=' .. vim.inspect(position_arguments))
                found = self:_handle_position_arguments(argument, position_arguments, namespace)

                if not found then
                    -- TODO: Do something about this one
                end
            end
        elseif argument.argument_type == argparse.ArgumentType.named then
            local found = self:_handle_flag_arguments(flag_arguments, argument, namespace)

            if not found then
                -- TODO: Do something about this one
            end
        end
    end

    return namespace
end


return M
