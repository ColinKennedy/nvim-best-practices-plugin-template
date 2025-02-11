--- Run the is file before you run unittests to download any extra dependencies.

local _PLUGINS = {
    ["https://github.com/nvim-lualine/lualine.nvim"] = os.getenv("LUALINE_DIR") or "/tmp/lualine.nvim",
    ["https://github.com/nvim-telescope/telescope.nvim"] = os.getenv("TELESCOPE_DIR") or "/tmp/telescope.nvim",
    ["https://github.com/ColinKennedy/mega.cmdparse"] = os.getenv("MEGA_CMDPARSE_DIR") or "/tmp/mega.cmdparse",
    ["https://github.com/ColinKennedy/mega.logging"] = os.getenv("MEGA_LOGGING_DIR") or "/tmp/mega.logging",
}

local cloned = false

for url, directory in pairs(_PLUGINS) do
    if vim.fn.isdirectory(directory) ~= 1 then
        print(string.format('Cloning "%s" plug-in to "%s" path.', url, directory))

        vim.fn.system({ "git", "clone", url, directory })

        cloned = true
    end

    vim.opt.rtp:append(directory)
end

if cloned then
    print("Finished cloning.")
end

vim.opt.rtp:append(".")

vim.cmd("runtime plugin/plugin_template.lua")

require("lualine").setup()

require("plugin_template._core.configuration").initialize_data_if_needed()
