--- Run the is file before you run unittests to download any extra dependencies.

local _PLUGINS = {
    ["https://github.com/nvim-lualine/lualine.nvim"] = os.getenv("LUALINE_DIR") or "/tmp/lualine.nvim",
    ["https://github.com/nvim-telescope/telescope.nvim"] = os.getenv("TELESCOPE_DIR") or "/tmp/telescope.nvim",
    ["https://github.com/nvim-lua/plenary.nvim"] = os.getenv("PLENARY_DIR") or "/tmp/plenary.nvim",
}

for url, directory in pairs(_PLUGINS) do
    vim.fn.system({ "git", "clone", url, directory })

    vim.opt.rtp:append(directory)
end

vim.opt.rtp:append(".")

vim.cmd("runtime plugin/plugin_template.lua")

require("lualine").setup()
