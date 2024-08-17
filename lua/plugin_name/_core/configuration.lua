--- All functions and data to help customize `plugin_name` for this user.
---
--- @module 'plugin_name._core.configuration'
---

local M = {}

-- TODO: Finish this later
--- @class PluginNameConfiguration
---     The user's customizations for this plugin.
---

local _DATA = {}
local _DEFAULTS = {}


--- Setup `plugin_name` for the first time, if needed.
local function _initialize_data_if_needed()
  if vim.g.loaded_plugin_name then
    return
  end

  _DATA = vim.tbl_deep_extend(
    "force",
    _DEFAULTS,
    vim.g.plugin_name_configuration or {}
  )

  vim.g.loaded_plugin_name = true
end

--- Merge `data` with the user's current configuration.
---
--- @param data PluginNameConfiguration? All extra customizations for this plugin.
---
function M.resolve_data(data)
  _initialize_data_if_needed()

  return vim.tbl_deep_extend("force", _DATA, data or {})
end

return M
