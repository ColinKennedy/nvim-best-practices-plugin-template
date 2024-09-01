--- The file that auto-creates documentation for `plugin_template`.

local success, doc = pcall(require, "mini.doc")

if not success then
    error("mini.doc is required to run this script. Please clone + source https://github.com/echasnovski/mini.doc")
end

---@diagnostic disable-next-line: undefined-field
if _G.MiniDoc == nil then
    doc.setup()
end

---@class MiniDoc.Hooks
---    Customization options during documentation generation. It can control
---    section headers, newlines, etc.
---@field sections table<string, fun(data: any): nil>
---    When a section is visited by the documentation generator, this table is
---    consulted to decide what to do with that section.

---@class MiniDoc.SectionInfo
---    A description of what this section is meant to display / represent.
---@field id string
---    The section label. e.g. `"@param"`, `"@return"`, etc.

---@class MiniDoc.Section
---    A renderable blob of text (which will later auto-create into documentation).
---    This class is from mini.doc. We're just type-annotating it so `llscheck` is happy.
---@see https://github.com/echasnovski/mini.doc
---@field info MiniDoc.SectionInfo
---    A description of what this section is meant to display / represent.
---@field parent MiniDoc.Section?
---    The section that includes this instance as one of its children, if any.
---@field parent_index number?
---    If a `parent` is defined, this is the position of this instance in `parent`.
---@field type string
---    A description about what this object is. Is it a section or a block or
---    something else? Stuff like that.
---
local _Section = {} -- luacheck: ignore 241 -- variable never accessed

--- Add `child` to this instance at `index`.
---
---@param index number The 1-or-more position to add `child` into.
---@param child string The text to add.
---
function _Section:insert(index, child) end -- luacheck: ignore 212 -- unused argument

--- Remove a child from this instance at `index`.
---
---@param index number? The 1-or-more position to remove `child` from.
---
function _Section:remove(index) end -- luacheck: ignore 212 -- unused argument

--- Check if `text` is the start of a function's parameters.
---
---@param text string Some text. e.g. `"Parameters ~"`.
---@return boolean # If it's a section return `true`.
---
local function _is_field_section(text)
    return text:match("%s*Fields%s*~%s*")
end

--- Check if `text` is the start of a function's parameters.
---
---@param text string Some text. e.g. `"Parameters ~"`.
---@return boolean # If it's a section return `true`.
---
local function _is_parameter_section(text)
    return text:match("%s*Parameters%s*~%s*")
end

--- Check if `text` is the start of a function's parameters.
---
---@param text string Some text. e.g. `"Return ~"`.
---@return boolean # If it's a section return `true`.
---
local function _is_return_section(text)
    return text:match("%s*Return%s*~%s*")
end

--- Add the text that Vimdoc uses to generate doc/tags (basically surround the text with *s).
---
---@param text string Any text, e.g. `"plugin_template.ClassName"`.
---@return string # The wrapped text, e.g. `"*plugin_template.ClassName*"`.
---
local function _add_tag(text)
    return (text:gsub("(%S+)", "%*%1%*"))
end

--- Run `caller` on `section` and all of its children recursively.
---
---@param caller fun(section: MiniDoc.Section): nil A callback used to modify its given `section`.
---@param section MiniDoc.Section The starting point to traverse underneath.
---
local function _apply_recursively(caller, section)
    caller(section)

    if type(section) == "table" then
        for _, t in ipairs(section) do
            _apply_recursively(caller, t)
        end
    end
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

--- Add leading whitespace to `text`, if `text` is not an empty line.
---
---@param text string The text to modify, maybe.
---@return string # The modified `text`, as needed.
---
local function _indent(text)
    if not text or text == "" then
        return text
    end

    return "    " .. text
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

--- Add newlines around `section` if needed.
---
---@param section MiniDoc.Section
---    The object to possibly modify.
---@param count number?
---    The number of lines to put before `section` if needed. If the section
---    has more newlines than `count`, it is converted back to `count`.
---
local function _set_trailing_newline(section, count)
    local function _is_not_whitespace(text)
        return text:match("%S+")
    end

    count = count or 1
    local found_text = false
    local lines = 0

    for _, line in ipairs(section) do
        if not found_text then
            if _is_not_whitespace(line) then
                found_text = true
            end
        elseif _is_not_whitespace(line) then
            lines = 0
        else
            lines = lines + 1
        end
    end

    if count > lines then
        for _ = 1, count - lines do
            section:insert(1, "")
        end
    else
        for _ = 1, lines - count do
            section:remove(1)
        end
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
---@return MiniDoc.Hooks
---    All of the generated callbacks.
---
local function _get_module_enabled_hooks(module_identifier)
    local module_name = nil

    local hooks = vim.deepcopy(doc.default_hooks)

    hooks.sections["@class"] = function(section)
        if #section == 0 or section.type ~= "section" then
            return
        end

        section[1] = _add_tag(section[1])
    end

    local original_field_hook = hooks.sections["@field"]

    hooks.sections["@field"] = function(section)
        original_field_hook(section)

        for index, line in ipairs(section) do
            section[index] = _indent(line)
        end
    end

    hooks.sections["@module"] = function(section)
        module_name = _strip_quotes(section[1])

        section:clear_lines()
    end

    local original_param_hook = hooks.sections["@param"]

    hooks.sections["@param"] = function(section)
        original_param_hook(section)

        for index, line in ipairs(section) do
            section[index] = _indent(line)
        end
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
            _replace_function_name(section, module_identifier, module_name)
        end

        original_tag_hook(section)
    end

    local original_block_post_hook = hooks.block_post

    hooks.block_post = function(block)
        original_block_post_hook(block)

        if not block:has_lines() then
            return
        end

        _apply_recursively(function(section)
            if not (type(section) == "table" and section.type == "section") then
                return
            end

            if section.info.id == "@field" and _is_field_section(section[1]) then
                local previous_section = section.parent[section.parent_index - 1]

                if previous_section then
                    _set_trailing_newline(section)
                end
            end

            if section.info.id == "@param" and _is_parameter_section(section[1]) then
                local previous_section = section.parent[section.parent_index - 1]

                if previous_section then
                    _set_trailing_newline(previous_section)
                end
            end

            if section.info.id == "@return" and _is_return_section(section[1]) then
                local previous_section = section.parent[section.parent_index - 1]

                if previous_section then
                    _set_trailing_newline(section)
                end
            end
        end, block)
    end

    -- TODO: Add alias support. These lines effectively clear aliases, which is a shame.
    hooks.section_pre = function(...) -- luacheck: ignore 212 -- unused argument
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
local function _get_module_identifier(path) -- luacheck: ignore 212 -- unused argument
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
    local root = vim.fs.normalize(vim.fs.joinpath(current_directory, "..", ".."))
    local paths = {
        {
            source = vim.fs.joinpath(root, "lua", "plugin_template", "init.lua"),
            destination = vim.fs.joinpath(root, "doc", "plugin_template_api.txt"),
        },
        {
            source = vim.fs.joinpath(root, "lua", "plugin_template", "types.lua"),
            destination = vim.fs.joinpath(root, "doc", "plugin_template_types.txt"),
        },
    }

    _validate_paths(paths)

    for _, entry in ipairs(paths) do
        local source = entry.source
        local destination = entry.destination

        local module_identifier = _get_module_identifier(source)
        local hooks = _get_module_enabled_hooks(module_identifier)

        doc.generate({ source }, destination, { hooks = hooks })
    end
end

main()
