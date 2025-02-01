-- A template that will be replaced by the .github/workflows/release-luarocks.yml file
--
-- Reference:
--     Example template https://github.com/nvim-neorocks/luarocks-tag-release/blob/master/resources/rockspec.template
--

local git_ref = "$git_ref"
local modrev = "$modrev"
local specrev = "$specrev"

local repo_url = "$repo_url"

rockspec_format = "3.0"
package = "nvim-best-practices-plugin-template"
version = modrev .. "-" .. specrev

local user = "ColinKennedy"

description = {
    homepage = "https://github.com/" .. user .. "/" .. package,
    labels = { "neovim", "neovim-plugin" },
    license = "MIT",
    summary = 'A "Best Practices" Neovim plugin template',
}

dependencies = {
    "mega.cmdparse >= 1.0.3, < 2.0",
    "mega.logging >= 1.1.4, < 2.0",

    -- TODO(you): Remove these dependencies if you don't need them
    -- "lualine.nvim", -- Reference: https://luarocks.org/modules/neorocks/lualine.nvim
    "telescope.nvim >= 0.1.8 < 1.0",
}

test_dependencies = {
    "busted >= 2.0, < 3.0",
    "lua >= 5.1, < 6.0",
}

-- Reference: https://github.com/luarocks/luarocks/wiki/test#test-types
test = { type = "busted" }

source = {
    url = repo_url .. "/archive/" .. git_ref .. ".zip",
    dir = "$repo_name-" .. "$archive_dir_suffix",
}

if modrev == "scm" or modrev == "dev" then
    source = {
        url = repo_url:gsub("https", "git"),
    }
end

build = {
    type = "builtin",
    copy_directories = $copy_directories,
}
