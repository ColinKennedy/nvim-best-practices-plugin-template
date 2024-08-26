local directory = os.getenv("LUALINE_DIR") or "/tmp/lualine.nvim"

vim.fn.system({
  "git",
  "clone",
  "https://github.com/nvim-lualine/lualine.nvim",
  directory,
})


vim.opt.rtp:append(directory)

vim.opt.rtp:append(".")

vim.cmd("runtime plugin/plugin_template.lua")
