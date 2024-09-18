local doc = require("mini.doc")


if _G.MiniDoc == nil then
    doc.setup()
end


local function _strip_quotes(text)
    return text:gsub("^['\"](.-)['\"]$", "%1")
end


local function _get_last_numeric_key(section)
    local found = nil

    for key, _ in pairs(section) do
        if type(key) ~= "number" then
            return found
        end

        found = key
    end
end


local function _add_before_after_whitespace(section)
    section:insert(1, "")
    local last = _get_last_numeric_key(section)
    section:insert(last + 1, "")
end


local function _get_destination_path(source, destination_directory)
    -- Example: source == /tmp/foo.lua, file_name == foo.txt
    local file_name = vim.fn.fnamemodify(source, ":t:r") .. ".txt"

    return vim.fs.joinpath(destination_directory, file_name)
end

local function _replace_function_name(section, module_identifier, module_name)
    local prefix = string.format("^%s%%.", module_identifier)
    local replacement = string.format("%s.", module_name)

    for index, line in ipairs(section) do
        line = line:gsub(prefix, replacement)
        section[index] = line
    end
end

local function _get_module_enabled_hooks(module_identifier)
    local module_name = nil

    local hooks = vim.deepcopy(doc.default_hooks)
    hooks.sections["@module"] = function(section)
        module_name = _strip_quotes(section[1])

        section:clear_lines()
    end

    local original = hooks.sections["@signature"]

    hooks.sections["@signature"] = function(section)
        if module_identifier then
            _replace_function_name(section, module_identifier, module_name)
        end

        _add_before_after_whitespace(section)

        return original(section)
    end

    return hooks
end


local function _get_script_directory()
    local path = debug.getinfo(1, "S").source:sub(2) -- Remove the '@' at the start

    return path:match("(.*/)")
end


local function _get_module_identifier(path)
    -- TODO: Need to replace this later
    return "M"
end


local function _validate_paths(paths)
    for _, entry in ipairs(paths) do
        if vim.fn.filereadable(entry.source) ~= 1 then
            error(string.format('Source "%s" is not readable.', vim.inspect(entry)))
        end
    end
end


local function main()
    local current_directory = _get_script_directory()
    local root = vim.fs.normalize(vim.fs.joinpath(current_directory, ".."))
    local paths = {
        {
            source = vim.fs.joinpath( root, "lua", "plugin_template", "init.lua" ),
            destination = vim.fs.joinpath( root, "doc", "plugin_template_api.txt" ),
        }
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
