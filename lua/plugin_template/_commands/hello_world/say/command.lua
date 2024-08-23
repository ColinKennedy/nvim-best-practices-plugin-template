--- The main file that implements `hello-world say` outside of COMMAND mode.
---
--- @module 'plugin_template._commands.say.command'
---

local constant = require("plugin_template._commands.hello_world.say.constant")
local state = require("plugin_template._core.state")

local M = {}

M._print = print

--- Print `phrase` according to `configuration`.
---
--- @param phrase string[]
---     The text to say.
--- @param repeat_? number
---     A 1-or-more value. The number of times to print `word`.
--- @param style? string
---     Control how the text should be shown.
---
local function _say(phrase, repeat_, style)
    state.PREVIOUS_COMMAND = "hello_world"

    repeat_ = repeat_ or 1
    style = style or constant.Keyword.style.lowercase
    local text = vim.fn.join(phrase, " ")

    if style == constant.Keyword.style.lowercase then
        text = string.lower(text)
    elseif style == constant.Keyword.style.uppercase then
        text = string.upper(text)
    end

    for _ = 1, repeat_ do
        M._print(text)
    end
end

--- Print `phrase` according to `configuration`.
---
--- @param phrase string[]
---     The text to say.
--- @param repeat_? number
---     A 1-or-more value. The number of times to print `word`.
--- @param style? string
---     Control how the text should be shown.
---
function M.run_say_phrase(phrase, repeat_, style)
    print("Saying phrase")

    _say(phrase, repeat_, style)
end

--- Print `word` according to `configuration`.
---
--- @param word string
---     The text to say.
--- @param repeat_? number
---     A 1-or-more value. The number of times to print `word`.
--- @param style? string
---     Control how the text should be shown.
---
function M.run_say_word(word, repeat_, style)
    print("Saying word")

    word = vim.fn.split(word, " ")[1] -- Make sure it's only one word
    _say({ word }, repeat_, style)
end

return M
