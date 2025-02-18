-- TODO: Replace with relative paths once it's confirmed working
local logging =
    "/home/selecaoone/repositories/personal/.config/nvim/bundle/nvim-best-practices-plugin-template/.dependencies/mega.logging/lua"

local root =
    "/home/selecaoone/repositories/personal/.config/nvim/bundle/nvim-best-practices-plugin-template/.dependencies/mega.busted/lua"
package.path = logging .. "/?.lua;" .. package.path
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path

-- print(package.searchpath('mega.logging', package.path))
-- print(package.searchpath('pl', package.path))
-- error('stop')

-- TODO: check for dependencies first

---@type string[]
local arguments = {}

for _, item in ipairs(arg or {}) do
    table.insert(arguments, item)
end

require("mega.busted.make_standalone_profile").main(arguments)
