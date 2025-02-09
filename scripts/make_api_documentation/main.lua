--- The file that auto-creates documentation for `plugin_template`.

local vimdoc = require("mega.vimdoc")

---@return string # Get the directory on-disk where this Lua file is running from.
local function _get_script_directory()
    local path = debug.getinfo(1, "S").source:sub(2) -- Remove the '@' at the start

    return path:match("(.*/)")
end

--- Convert the files in this plug-in from Lua docstrings to Vimdoc documentation.
local function main()
    local current_directory = _get_script_directory()
    local root = vim.fs.normalize(vim.fs.joinpath(current_directory, "..", ".."))

    vimdoc.make_documentation_files({
        {
            source = vim.fs.joinpath(root, "lua", "plugin_template", "init.lua"),
            destination = vim.fs.joinpath(root, "doc", "plugin_template_api.txt"),
        },
        {
            source = vim.fs.joinpath(root, "lua", "plugin_template", "types.lua"),
            destination = vim.fs.joinpath(root, "doc", "plugin_template_types.txt"),
        },
    }, { enable_module_in_signature = false })
end

main()
