--- The main file that implements `goodnight-moon read` outside of COMMAND mode.

local logging = require("mega.logging")

local _LOGGER = logging.get_logger("plugin_template._commands.goodnight_moon.read")

local M = {}

--- Print the name of the book.
---
---@param book string The name of the book.
---
function M.run(book)
    _LOGGER:debug("Running goodnight-moon count-sheep")

    vim.notify(string.format("%s: it is a book", book), vim.log.levels.INFO)
end

return M
