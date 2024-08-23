--- Register `plugin_template` to telescope.nvim.
---
--- @source https://github.com/nvim-telescope/telescope.nvim
---
--- @module 'telescope._extensions.plugin_template'
---

local has_telescope, telescope = pcall(require, "telescope")

--- TODO: REmove this later - https://github.com/dhruvmanila/browser-bookmarks.nvim/blob/main/lua/telescope/_extensions/bookmarks.lua

if not has_telescope then
  error("Telescope interface requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)")
end

local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local telescope_config = require("telescope.config").values

-- TODO: Add docstring

-- TODO: Run the command when something is selected

local function _run_goodnight_moon(options)
    local displayer = entry_display.create({
        separator = " ",
        items = {
            { width = 0.8 },
            { remaining = true },
        },
    })

    local function make_display(entry)
        local display_columns = { entry.name, { entry.author, "Comment" } }

        return displayer(display_columns)
    end

    local books = {
        { "Guns, Germs, and Steel: The Fates of Human Societies", "Jared M. Diamond" },
        {"Herodotus Histories", "Herodotus"},
        {"The Origin of Consciousness in the Breakdown of the Bicameral Mind", "Julian Jaynes"},
        {"What Every Programmer Should Know About Memory", "Ulrich Drepper"},
        {"When: The Scientific Secrets of Perfect Timing", "Daniel H. Pinker"},
    }

    pickers.new(options, {
        prompt_title = "Choose A Book",
        finder = finders.new_table({
            results = books,
            entry_maker = function(entry)
                local name, author = unpack(entry)
                local value = string.format("%s - %s", name, author)

                return {
                    display = make_display,
                    author = author,
                    name = name,
                    value = value,
                    ordinal = value,
                }
            end,
        }),
        previewer = false,
        sorter = telescope_config.generic_sorter(options),
    })
    :find()
end

local function _run_hello_world(options)
    local displayer = entry_display.create({
        separator = " ",
        items = { { width = 0.8 }, { remaining = true } },
    })

    local function make_display(entry)
        local display_columns = { entry.value }

        return displayer(display_columns)
    end

    local phrases = { "Hi there!" }

    pickers.new(options, {
        prompt_title = "Say Hello",
        finder = finders.new_table({
            results = phrases,
            entry_maker = function(entry)
                return {
                    display = make_display,
                    name = entry,
                    value = entry,
                    ordinal = entry,
                }
            end,
        }),
        previewer = false,
        sorter = telescope_config.generic_sorter(options),
    })
    :find()
end

return telescope.register_extension({
    exports = {
        ["goodnight-moon"] = _run_goodnight_moon,
        ["hello-world"] = _run_hello_world,
    },
})
