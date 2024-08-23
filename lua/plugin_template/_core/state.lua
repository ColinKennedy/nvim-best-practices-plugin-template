--- A file that keeps track of mutable data between command calls.
---
--- @module 'plugin_template._commands.say.state'
---

local M = {}

--- @type string?  The user's most recent command. (Used for lualine display).
M.PREVIOUS_COMMAND = nil

return M
