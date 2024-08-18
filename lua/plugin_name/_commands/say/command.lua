--- The main file that implements `hello-world say` outside of COMMAND mode.
---
--- @module 'plugin_name._commands.say.command'
---

local configuration_ = require("plugin_name._core.configuration")

local M = {}

--- Print `phrase` according to `configuration`.
---
--- @param phrase string[]
---     The text to say.
--- @param configuration PluginNameConfiguration?
---     Control how many times the phrase is said and the text's display.
---
local function _say(phrase, configuration)
    configuration = configuration_.resolve_data(configuration)

    for _=1,configuration.commands.hello_world.say["repeat"] do
        -- TODO: Add style here (uppercase / lowercase) + unittests
        print(vim.fn.join(phrase, " "))
    end
end

--- Print `phrase` according to `configuration`.
---
--- @param phrase string[] The text to say.
--- @param configuration PluginNameConfiguration?
---
function M.run_say_phrase(phrase, configuration)
    print("Saying phrase")

    _say(phrase, configuration)
end

--- Print `word` according to `configuration`.
---
--- @param word string The text to say.
--- @param configuration PluginNameConfiguration?
---
function M.run_say_word(word, configuration)
    print("Saying word")

    word = vim.fn.split(word, " ")[1]  -- Make sure it's only one word
    _say({word}, configuration)
end

return M
