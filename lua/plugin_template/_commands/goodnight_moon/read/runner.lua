--- The main file that implements `goodnight-moon read` outside of COMMAND mode.
---
--- @module 'plugin_template._commands.read.command'
---

local configuration = require("plugin_template._core.configuration")
local state = require("plugin_template._core.state")
local vlog = require("vendors.vlog")

local M = {}

M._print = print

--- Print the name of the book.
---
--- @param book string The name of the book.
---
function M.run(book)
    configuration.initialize_data_if_needed()
    vlog.debug("Running goodnight-moon count-sheep")

    state.PREVIOUS_COMMAND = "goodnight_moon"

    M._print(string.format("%s: it is a book", book))
end

return M
