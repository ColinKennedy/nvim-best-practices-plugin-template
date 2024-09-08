--- Register `plugin_template` to telescope.nvim.
---
---@source https://github.com/nvim-telescope/telescope.nvim
---
---@module 'telescope._extensions.plugin_template'
---

local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
    error("Telescope interface requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)")
end

local configuration = require("plugin_template._core.configuration")
local runner = require("telescope._extensions.plugin_template.runner")

-- NOTE: This file is defer-loaded so it's okay to run this in the global scope
configuration.initialize_data_if_needed()

--- Run the `:Telescope plugin_template goodnight-moon` command.
---
---@param options telescope.CommandOptions The Telescope UI / layout options.
---
local function _run_goodnight_moon(options)
    local picker = runner.get_goodnight_moon_picker(options)

    picker:find()
end

--- Run the `:Telescope plugin_template hello-world` command.
---
---@param options telescope.CommandOptions The Telescope UI / layout options.
---
local function _run_hello_world(options)
    local picker = runner.get_hello_world_picker(options)

    picker:find()
end

return telescope.register_extension({
    exports = {
        ["goodnight-moon"] = _run_goodnight_moon,
        ["hello-world"] = _run_hello_world,
    },
})
