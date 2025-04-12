--- Run the is file before you run unittests to download any extra dependencies.

local _PLUGINS = {
    ["https://github.com/ColinKennedy/mega.cmdparse"] = os.getenv("MEGA_CMDPARSE_DIR") or "/tmp/mega.cmdparse",
    ["https://github.com/ColinKennedy/mega.logging"] = os.getenv("MEGA_LOGGING_DIR") or "/tmp/mega.logging",

    ["https://github.com/nvim-lualine/lualine.nvim"] = os.getenv("LUALINE_DIR") or "/tmp/lualine.nvim",

    ["https://github.com/nvim-telescope/telescope.nvim"] = os.getenv("TELESCOPE_DIR") or "/tmp/telescope.nvim",
    -- IMPORTANT: Needed to prevent error:
    -- `telescope.nvim/lua/telescope/config.lua:1: module 'plenary.strings' not found`
    --
    ["https://github.com/nvim-lua/plenary.nvim"] = os.getenv("PLENARY_NVIM_DIR") or "/tmp/plenary.nvim",
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
