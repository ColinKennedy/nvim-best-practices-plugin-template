--- The main file that implements `goodnight-moon read` outside of COMMAND mode.
---
--- @module 'plugin_template._commands.read.command'
---

local state = require("plugin_template._core.state")
local vlog = require("plugin_template._vendors.vlog")

local M = {}


--- Print the name of the book.
---
--- @param book string The name of the book.
---
function M.run(book)
    vlog.debug("Running goodnight-moon count-sheep")

    state.PREVIOUS_COMMAND = "goodnight_moon"

    vim.notify(string.format("%s: it is a book", book), vim.log.levels.INFO)
end

return M
