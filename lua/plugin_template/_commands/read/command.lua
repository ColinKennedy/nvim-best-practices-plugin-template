--- The main file that implements `goodnight-moon read` outside of COMMAND mode.
---
--- @module 'plugin_template._commands.read.command'
---

local M = {}

M._print = print

--- Print the name of the book.
---
--- @param book string The name of the book.
---
function M.run(book)
    M._print(string.format("%s: it is a book", book))
end

return M
