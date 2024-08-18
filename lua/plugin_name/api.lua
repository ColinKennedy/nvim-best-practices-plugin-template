--- All function(s) that can be called externally by other Lua modules.
---
--- If a function's signature here changes in some incompatible way, this
--- package must get a new *major* version.
---
--- @module 'plugin_name.api'
---

local say_command = require("plugin_name._commands.say_command")

local M = {}

-- TODO: Make sure type-hinting works with this
M.run_hello_world_say = say_command.run_say

return M
