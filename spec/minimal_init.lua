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

-- -- If I do standalone = false, the printout shows tests ran. But then
-- -- the luacov is empty. If I don't do standalone = false then the
-- -- printout claims no tests ran but the luacov.stats.out file exists
-- -- In either case, it only works with `nvim -l`. If i use `busted` doesn't seem to ever produce a luacov.stats.out file
-- print('DEBUGPRINT[2]: minimal_init.lua:40: _G.arg=' .. vim.inspect(_G.arg))
-- print('DEBUGPRINT[3]: minimal_init.lua:41: arg=' .. vim.inspect(arg))
-- -- _G.arg = { "--ignore-lua",
-- --   [0] = "spec/minimal_init.lua"
-- -- }
-- -- require("luacov")
-- require("busted.runner")({standalone=false})

-- require("luacov")
-- require("busted.runner")()

-- print('DEBUGPRINT[1]: minimal_init.lua:36: _G.arg=' .. vim.inspect(_G.arg))
-- _G.arg = {"coverage", [0]="spec/plugin_template/configuration_spec.lua"}
-- require("busted.runner")({standalone=false})
