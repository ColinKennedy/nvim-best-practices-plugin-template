--- The main file that implements `hello-world say` outside of COMMAND mode.
---
---@module 'plugin_template._commands.hello_world.say.runner'
---

local constant = require("plugin_template._commands.hello_world.say.constant")
local vlog = require("plugin_template._vendors.vlog")

local M = {}

--- Check if `text` is only whitespace.
---
---@param text string Some words / phrase to check.
---@return boolean # If `text` has only whitespace, return `true`.
---
local function _is_whitespace(text)
    return text:match("^%s*$") == nil
end

--- Remove any phrases from `text` that has no meaningful words.
---
---@param text string[] All of the words to check.
---@return string[] # The non-empty text.
---
local function _filter_missing_strings(text)
    local output = {}

    for _, phrase in ipairs(text) do
        if _is_whitespace(phrase) then
            table.insert(output, phrase)
        end
    end

    return output
end

--- Print `phrase` according to the other options.
---
---@param phrase string[]
---    The text to say.
---@param repeat_? number
---    A 1-or-more value. The number of times to print `word`.
---@param style? string
---    Control how the text should be shown.
---
local function _say(phrase, repeat_, style)
    repeat_ = repeat_ or 1
    style = style or constant.Keyword.style.lowercase
    local text = vim.fn.join(phrase, " ")

    if style == constant.Keyword.style.lowercase then
        text = string.lower(text)
    elseif style == constant.Keyword.style.uppercase then
        text = string.upper(text)
    end

    for _ = 1, repeat_ do
        vim.notify(text, vim.log.levels.INFO)
    end
end

--- Print `phrase` according to the other options.
---
---@param phrase string[]
---    The text to say.
---@param repeat_ number?
---    A 1-or-more value. The number of times to print `word`.
---@param style string?
---    Control how the text should be shown.
---
function M.run_say_phrase(phrase, repeat_, style)
    vlog.debug("Running hello-world say word.")

    phrase = _filter_missing_strings(phrase)

    if vim.tbl_isempty(phrase) then
        vim.notify("No phrase was given", vim.log.levels.INFO)

        return
    end

    vim.notify("Saying phrase", vim.log.levels.INFO)

    _say(phrase, repeat_, style)
end

--- Print `phrase` according to the other options.
---
---@param word string
---    The text to say.
---@param repeat_ number?
---    A 1-or-more value. The number of times to print `word`.
---@param style string?
---    Control how the text should be shown.
---
function M.run_say_word(word, repeat_, style)
    vlog.debug("Running hello-world say word.")

    if word == "" then
        vim.notify("No word was given", vim.log.levels.INFO)

        return
    end

    word = vim.fn.split(word, " ")[1] -- Make sure it's only one word

    vim.notify("Saying word", vim.log.levels.INFO)

    _say({ word }, repeat_, style)
end

return M
