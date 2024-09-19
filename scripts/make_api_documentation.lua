--- The file that auto-creates documentation for `plugin_template`.

local success, doc = pcall(require, "mini.doc")

if not success then
    error(
        "mini.doc is required to run this script. "
        .. "Please clone + source https://github.com/echasnovski/mini.doc"
    )
end


if _G.MiniDoc == nil then
    doc.setup()
end

--- Add the text that Vimdoc uses to generate doc/tags (basically surround the text with *s).
---
---@param text string Any text, e.g. `"plugin_template.ClassName"`.
---@return string # The wrapped text, e.g. `"*plugin_template.ClassName*"`.
---
local function _add_tag(text)
    return (text:gsub('(%S+)', '%*%1%*'))
end

--- Remove any quotes around `text`.
---
---@param text string
---    Text that might have prefix / suffix quotes. e.g. `'foo'`.
---@return string
---    The `text` but without the quotes. Inner quotes are retained. e.g.
---    `'foo"bar'` becomes `foo"bar`.
---
local function _strip_quotes(text)
    return (text:gsub("^['\"](.-)['\"]$", "%1"))
end


--- Get the last (contiguous) key in `data` that is numbered.
---
---`data` might be a combination of number or string keys. The first key is
---expected to be numbered. If so, we get the last key that is a number.
---
---@param data table<number | string, any> The data to check.
---@return number # The last found key.
---
local function _get_last_numeric_key(data)
    local found = nil

    for key, _ in pairs(data) do
        if type(key) ~= "number" then
            if not found then
                error("No number key could be found.")
            end

            return found
        end

        found = key
    end

    return found
end


--- Ensure there is one blank space around `section` by modifying it.
---
---@param section MiniDoc.Section
---    A renderable blob of text (which will later auto-create into documentation).
---
local function _add_before_after_whitespace(section)
    section:insert(1, "")
    local last = _get_last_numeric_key(section)
    section:insert(last + 1, "")
end

--- Change the function name in `section` from `module_identifier` to `module_name`.
---
---@param section MiniDoc.Section
---    A renderable blob of text (which will later auto-create into documentation).
---    We assume this `section` represents a Lua function.
---@param module_identifier string
---    Usually a function in Lua is defined with `function M.foo`. In this
---    example, `module_identifier` would be the `M` part.
---@param module_name string
---    The real name for the module. e.g. `"plugin_template"`.
---
local function _replace_function_name(section, module_identifier, module_name)
    local prefix = string.format("^%s%%.", module_identifier)
    local replacement = string.format("%s.", module_name)

    for index, line in ipairs(section) do
        line = line:gsub(prefix, replacement)
        section[index] = line
    end
end

--- Remove the prefix identifier (usually `"M"`, from `"M.get_foo"`).
---
---@param section MiniDoc.Section
---    A renderable blob of text (which will later auto-create into documentation).
---@param module_identifier string
---    If provided, any reference to this identifier (e.g. `M`) will be
---    replaced with the real import path.
---
local function _strip_function_identifier(section, module_identifier)
    local prefix = string.format("^%s%%.", module_identifier)

    for index, line in ipairs(section) do
        line = line:gsub(prefix, "")
        section[index] = line
    end
end

--- Create the callbacks that we need to create our documentation.
---
---@param module_identifier string?
---    If provided, any reference to this identifier (e.g. `M`) will be
---    replaced with the real import path.
---@return MiniDoc.Hook[]
---    All of the generated callbacks.
---
local function _get_module_enabled_hooks(module_identifier)
    local module_name = nil

    local hooks = vim.deepcopy(doc.default_hooks)

    hooks.sections["@class"] = function(section)
        if #section == 0 or section.type ~= "section" then return end

        section[1] = _add_tag(section[1])
    end

    hooks.sections["@module"] = function(section)
        module_name = _strip_quotes(section[1])

        section:clear_lines()
    end

    local original_signature_hook = hooks.sections["@signature"]

    hooks.sections["@signature"] = function(section)
        if module_identifier then
            _strip_function_identifier(section, module_identifier)
        end

        _add_before_after_whitespace(section)

        original_signature_hook(section)

        -- NOTE: Remove the leading whitespace caused by MiniDoc
        for index, text in ipairs(section) do
            section[index] = (text:gsub("^%s+", ""))
        end
    end

    local original_tag_hook = hooks.sections["@tag"]

    hooks.sections["@tag"] = function(section)
        if module_identifier and module_name then
            _replace_function_name( section,
                module_identifier,
                module_name
            )
        end

        original_tag_hook(section)
    end

    hooks.write_pre = function(lines)
        table.insert(lines, #lines - 1, "WARNING: This file is auto-generated. Do not edit it!")

        return lines
    end

    return hooks
end

---@return string # Get the directory on-disk where this Lua file is running from.
local function _get_script_directory()
    local path = debug.getinfo(1, "S").source:sub(2) -- Remove the '@' at the start

    return path:match("(.*/)")
end

--- Parse `path` to find the source code that refers to the user's Lua file, if any.

---@param path string
---    The absolute path to a Lua file on-disk that we assume may have a line
---    like `return M` at the bottom which exports 0-or-more Lua classes / functions.
---@return string?
---    The found identifier. By convention it's usually `"M"` or nothing.
---
local function _get_module_identifier(path)
    -- TODO: Need to replace this later
    -- Ignore weird returns
    -- Only get the last return
    return "M"
end

---@class plugin_template.AutoDocumentationEntry
---    The simple source/destination of "Lua file that we want to auto-create
---    documentation from + the .txt file that we want auto-create to".
---@field source string
---    An absolute path to a Lua file on-disk. e.g. `"/path/to/init.lua"`.
---@field destination string
---    An absolute path for the auto-created documentation.
---    e.g. `"/out/plugin_template.txt"`.

--- Make sure `paths` can be processed by this script.
---
---@param paths plugin_template.AutoDocumentationEntry[]
---    The source/destination pairs to check.
---
local function _validate_paths(paths)
    for _, entry in ipairs(paths) do
        if vim.fn.filereadable(entry.source) ~= 1 then
            error(string.format('Source "%s" is not readable.', vim.inspect(entry)))
        end
    end
end

--- Convert the files in this plug-in from Lua docstrings to Vimdoc documentation.
local function main()
    local current_directory = _get_script_directory()
    local root = vim.fs.normalize(vim.fs.joinpath(current_directory, ".."))
    local paths = {
        {
            source = vim.fs.joinpath( root, "lua", "plugin_template", "init.lua" ),
            destination = vim.fs.joinpath( root, "doc", "plugin_template_api.txt" ),
        },
        {
            source = vim.fs.joinpath( root, "lua", "plugin_template", "types.lua" ),
            destination = vim.fs.joinpath( root, "doc", "plugin_template_types.txt" ),
        },
    }

    _validate_paths(paths)

    for _, entry in ipairs(paths) do
        local source = entry.source
        local destination = entry.destination

        local module_identifier = _get_module_identifier(source)
        local hooks = _get_module_enabled_hooks(module_identifier)

        doc.generate({source}, destination, { hooks = hooks })
    end
end


main()
