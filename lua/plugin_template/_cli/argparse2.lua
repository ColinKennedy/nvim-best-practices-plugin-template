--- Parse text into positional / named arguments.
---
--- @module 'plugin_template._cli.argparse2'
---

-- TODO: Clean-up code

-- TODO: Add unittest for required subparsers
 -- - set_required must fail if subparsers has no dest

local argparse = require("plugin_template._cli.argparse")
local argparse_helper = require("plugin_template._cli.argparse_helper")
local tabler = require("plugin_template._core.tabler")

--- @alias Action "append" | "count" | "store_false" | "store_false" | fun(data: ActionData): nil
---     This controls the behavior of how parsed arguments are added into the
---     final parsed `Namespace`.

--- @alias Namespace table<string, ...> All parsed values.

--- @class ActionData
---     A struct of data that gets passed to an Argument's action.
--- @field name string
---     The argument name to set/append/etc some `value`.
--- @field namespace Namespace
---     The container where parsed argument + value will go into. This
---     object gets directly modified when an action is called.
--- @field value ...
---     A value to add into `namespace`.

--- @class ArgumentOptions
---     All of the settings to include in a new parse argument.
--- @field action Action?
---     This controls the behavior of how parsed arguments are added into the
---     final parsed `Namespace`.
--- @field destination string?
---     When a parsed `Namespace` is created, this field is used to store
---     the final parsed value(s). If no `destination` is given an
---     automatically assigned name is used instead.
--- @field names string[] or string
---     The ways to refer to this instance.
--- @field parent ArgumentParser
---     The parser that owns this instance.
--- @field type ("number" | "string" | fun(value: string): ...)?
---     The expected output type. If a function is given, assume that the user
---     knows what they're doing and use their function's return value.

--- @class ArgumentParserOptions
---     The options that we might pass to `ArgumentParser.new`.
--- @field description string
---     Explain what this parser is meant to do and the argument(s) it needs.
---     Keep it brief (< 88 characters).
--- @field name string?
---     The parser name. This only needed if this parser has a parent subparser.
--- @field parent Subparsers?
---     A subparser that own this `ArgumentParser`, if any.

--- @class ArgumentParser
---     A starting point for arguments (positional arguments, flag arguments, etc).
--- @field description string
---     Explain what this parser is meant to do and the argument(s) it needs.
---     Keep it brief (< 88 characters).
--- @field name string?
---     The parser name. This only needed if this parser has a parent subparser.

--- @class SubparsersOptions
---     Customization options for the new Subparsers.
--- @field description string
---     Explain what types of parsers this object is meant to hold Keep it
---     brief (< 88 characters).
--- @field destination string
---     An internal name to track this subparser group.

--- @class Subparsers A group of parsers.

local M = {}

-- TODO: Add support for this later
local _ONE_OR_MORE = "__one_or_more"
local _ZERO_OR_MORE = "__zero_or_more"

--- @class Argument
---     An optional / required argument for some parser.
--- @field action Action?
---     This controls the behavior of how parsed arguments are added into the
---     final parsed `Namespace`.
--- @field destination string?
---     When a parsed `Namespace` is created, this field is used to store
---     the final parsed value(s). If no `destination` is given an
---     automatically assigned name is used instead.
---
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
        return string.format(
            'ArgumentParser({name="%s", description="%s"})',
            parser.name,
            parser.description
        )
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


--- Check if `text`.
---
--- @param text string Some text. e.g. `--foo`.
--- @return boolean # If `text` is a word, return `true.
---
local function _is_position_name(text)
    return text:sub(1, 1):match("%w")
end


--- Check if `text` is only spaces.
---
--- @param text string Some word / phrase to check. e.g. `" "`.
--- @return boolean # If `text` has non-empty alphanumeric character(s), return `true`.
---
local function _is_whitespace(text)
    return text:match("%s+")
end


--- Get the raw argument name. e.g. `"--foo"`.
---
--- Important:
---     If `argument` is a flag, this function must return back the prefix character(s) too.
---
--- @param argument FlagArgument | PositionArgument Some named argument to get text from.
--- @return string # The found name.
---
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


--- Strip argument name of any flag / prefix text. e.g. `"--foo"` becomes `"foo"`.
---
--- @param text string Some raw argument name. e.g. `"--foo"`.
--- @return string # The (clean) argument mame. e.g. `"foo"`.
---
local function _get_nice_name(text)
    return text:match("%W*(%w+)")
end

--- Find a proper type converter from `options`.
---
--- @param options ArgumentOptions The suggested type for an argument.
--- @return ArgumentOptions # An "expanded" variant of the orginal `options`.
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
--- Make sure an `Argument` has a name and every name is the same type.
---
--- If `names` is `{"foo", "-f"}` then this function will error.
---
--- @param names string[] All arguments to check.
---
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


--- Make sure a name was provided from `options`.
---
--- @param options ArgumentParserOptions
---
local function _validate_name(options)
    -- TODO: name is required
    if not options.name or _is_whitespace(options.name) then
        error(string.format('Argument "%s" must have a name.', vim.inspect(options)))
    end
end


--- Create a new group of parsers.
---
--- @param options SubparsersOptions Customization options for the new Subparsers.
--- @return Subparsers # A group of parsers (which will be filled with parsers later).
---
function M.Subparsers.new(options)
    local self = setmetatable({}, M.Subparsers)

    self.description = options.description
    self.destination = options.destination
    self._parsers = {}

    return self
end


--- Create a new `ArgumentParser` using `options`.
---
--- @param options ArgumentParserOptions The options to pass to `ArgumentParser.new`.
--- @return ArgumentParser # The created parser.
---
function M.Subparsers:add_parser(options)
    local new_options = vim.tbl_deep_extend("force", options, {parent = self})
    local parser = M.ArgumentParser.new(new_options)

    table.insert(self._parsers, parser)

    return parser
end


--- @return ArgumentParser[] # Get all of the child parsers for this instance.
function M.Subparsers:get_parsers()
    return self._parsers
end


--- Create a new instance using `options`.
---
--- @param options ArgumentOptions All of the settings to include in a new parse argument.
--- @return Argument # The created instance.
---
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
    self.names = options.names
    self.destination = options.destination or options.names[1]
    self:set_action(options.action)
    self._parent = options.parent

    return self
end


--- @return boolean # Check if this instance cannot be used anymore.
function M.Argument:is_exhausted()
    return self._used >= self._count
end


--- Get a function that mutates the namespace with a new parsed argument.
---
--- @return fun(data: ActionData): nil
---     A function that directly modifies the contents of `data`.
---
function M.Argument:get_action()
    return self._action
end


--- @return string # The (clean) argument mame. e.g. `"--foo"` becomes `"foo"`.
function M.Argument:get_nice_name()
    return _get_nice_name(self.destination or self.names[1])
end


--- Get a converter function that takes in a raw argument's text and outputs some converted result.
---
--- @return fun(value: string | boolean): ... # The converter function.
---
function M.Argument:get_type()
    return self._type
end


--- Use up more of the available use(s) of this instance.
---
--- Most arguments can only be used one time but some can be used multiple
--- times. This function takes up at least one of these available uses.
---
--- @param increment number? The number of uses to consume.
---
function M.Argument:increment_used(increment)
    increment = increment or 1
    self._used = self._used + increment
end


--- Describe how this argument should ingest new CLI value(s).
---
--- @param action Action The selected functionality.
---
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


-- TODO: need to add unittests for this.
--- Tell how many value(s) are needed to satisfy this instance.
---
--- e.g. nargs=2 means that every time this instance is detected there need to
--- be at least 2 values to ingest or it is not valid CLI input.
---
--- @param count string | number
---     The number of values we need for this instance. `"*"` ==  0-or-more,
---     `"+"` == 1-or-more. A number means there needs to exactly that many
---     arguments (no less no more).
---
function M.Argument:set_nargs(count)
    if count == "*" then
        count = _ZERO_OR_MORE
    elseif count == "+" then
        count = _ONE_OR_MORE
    end

    self._nargs = count
end


--- Create a new `ArgumentParser`.
---
--- If the parser is a child of a subparser then this instance must be given
--- a name via `{name="foo"}` or this function will error.
---
--- @param options ArgumentParserOptions
---     The options that we might pass to `ArgumentParser.new`.
--- @return ArgumentParser
---     The created instance.
---
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


--- @return Namespace # All default values from all (direct) child arguments.
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


--- @return string # A one/two liner explanation of this instance's expected arguments.
function M.ArgumentParser._get_usage_summary()
    -- TODO: Need to finish the concise args and also give advice on the next line
    return "usage: TODO"
end


--- Add `flags` to `namespace` if they match `argument`.
---
--- @param flags Argument[] All `-f`, `--foo`, etc arguments to check.
--- @param argument ArgparseArgument The argument to check for `flags` matches.
--- @param namespace Namespace # A container for the found match(es).
--- @return boolean # If a match was found, return `true`.
---
function M.ArgumentParser:_handle_flag_arguments(flags, argument, namespace)
    for _, flag in ipairs(flags) do
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


--- Add `positions` to `namespace` if they match `argument`.
---
--- @param positions Argument[] All `foo`, `bar`, etc arguments to check.
--- @param argument ArgparseArgument The argument to check for `positions` matches.
--- @param namespace Namespace # A container for the found match(es).
--- @return boolean # If a match was found, return `true`.
---
function M.ArgumentParser:_handle_position_arguments(positions, argument, namespace)
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


--- Check if `argument_name` matches a registered subparser.
---
--- @param data ArgparseResults The parsed arguments + any remainder text.
--- @param argument_name string A raw argument name. e.g. `foo`.
--- @param namespace Namespace An existing namespace to set/append/etc to the subparser.
--- @return boolean # If a match was found, return `true`.
---
function M.ArgumentParser:_handle_subparsers(data, argument_name, namespace)
    for _, subparser in ipairs(self._subparsers) do
        for _, parser in ipairs(subparser:get_parsers()) do
            if parser.name == argument_name then
                parser:parse_arguments(data, namespace)

                return true
            end
        end
    end

    return false
end


--- @return string # A one/two liner explanation of this instance's expected arguments.
function M.ArgumentParser:get_concise_help()
    return M.ArgumentParser._get_usage_summary()
end


--- @return string # A multi-liner explanation of this instance's expected arguments.
function M.ArgumentParser:get_full_help()
    -- TODO: Need to gather all options and print them
    local summary = M.ArgumentParser._get_usage_summary()

    return string.format("%s\n\noptions:%s", summary, "TODO")
end


--- Create a child argument so we can use it to parse text later.
---
--- @param options ArgumentOptions All of the settings to include in the new argument.
--- @return Argument # The created `Argument` instance.
---
function M.ArgumentParser:add_argument(options)
    local names = options.names

    if type(names) == "string" then
        names = {names}
    end

    local new_options = vim.tbl_deep_extend("force", options, ({names=names, parent=self}))
    local argument = M.Argument.new(new_options)

    if _is_position_name(names[1]) then
        table.insert(self._position_arguments, argument)
    else
        table.insert(self._flag_arguments, argument)
    end

    return argument
end


--- Create a group so we can add nested parsers underneath it later.
---
--- @param options SubparsersOptions Customization options for the new Subparsers.
--- @return Subparsers # A new group of parsers.
---
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


--- Parse user text `data`.
---
--- @param data string
---     User text that needs to be parsed. e.g. `hello "World!"`
--- @param namespace Namespace?
---     All pre-existing, default parsed values. If this is the first
---     ArgumentParser then this argument will always be empty but a nested
---     parser will usually have the parsed arguments of the parent subparsers
---     that were before it.
--- @return Namespace
---     All of the parsed data as one group.
---
function M.ArgumentParser:parse_arguments(data, namespace)
    if type(data) == "string" then
        data = argparse.parse_arguments(data)
    end

    namespace = namespace or {}
    namespace = vim.tbl_deep_extend(
        "force",
        self:_get_default_namespace(),
        namespace
    )

    local position_arguments = vim.deepcopy(self._position_arguments)
    local flag_arguments = vim.deepcopy(self._flag_arguments)

    for index, argument in ipairs(data.arguments) do
        if argument.argument_type == argparse.ArgumentType.position then
            local argument_name = _get_argument_name(argument)

            local found = self:_handle_subparsers(
                argparse_helper.lstrip_arguments(data, index + 1),
                argument_name,
                namespace
            )

            if not found then
                found = self:_handle_position_arguments(position_arguments, argument, namespace)

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
