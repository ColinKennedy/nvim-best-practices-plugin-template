--- Register `plugin_template` to telescope.nvim.
---
--- @source https://github.com/nvim-telescope/telescope.nvim
---
--- @module 'telescope._extensions.plugin_template_'
---

local M = {}

local action_state = require("telescope.actions.state")
local action_utils = require("telescope.actions.utils")
local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local telescope_actions = require("telescope.actions")
local telescope_config = require("telescope.config").values

local read_runner = require("plugin_template._commands.goodnight_moon.read.runner")
local say_runner = require("plugin_template._commands.hello_world.say.runner")

vim.api.nvim_set_hl(
    0,
    "PluginTemplateTelescopeEntry",
    {link="TelescopeResultsNormal", default=true}
)
vim.api.nvim_set_hl(
    0,
    "PluginTemplateTelescopeSecondary",
    {link="TelescopeResultsComment", default=true}
)

--- @alias TelescopeCommandOptions table<..., ...>

--- Run the `:Telescope plugin_template goodnight-moon` command.
---
--- @param options TelescopeCommandOptions The Telescope UI / layout options.
---
function M.get_goodnight_moon_picker(options)

    -- TODO: Make sure this picker actually works. It seems like it doesn't print
    local function _select_book(buffer)
        for _, book in ipairs(M.get_selection(buffer)) do
            read_runner.run(book)
        end

        telescope_actions.close(buffer)
    end

    local displayer = entry_display.create({
        separator = " ",
        items = {
            { width = 0.8 },
            { remaining = true },
        },
    })

    local books = {
        { "Guns, Germs, and Steel: The Fates of Human Societies", "Jared M. Diamond" },
        { "Herodotus Histories", "Herodotus" },
        { "The Origin of Consciousness in the Breakdown of the Bicameral Mind", "Julian Jaynes" },
        { "What Every Programmer Should Know About Memory", "Ulrich Drepper" },
        { "When: The Scientific Secrets of Perfect Timing", "Daniel H. Pinker" },
    }

    local picker = pickers
        .new(options, {
            prompt_title = "Choose A Book",
            finder = finders.new_table({
                results = books,
                entry_maker = function(data)
                    local name, author = unpack(data)
                    local value = string.format("%s - %s", name, author)

                    return {
                        display = function(entry)
                            return displayer({
                                { entry.name, "PluginTemplateTelescopeEntry" },
                                { entry.author, "PluginTemplateTelescopeSecondary" },
                            })
                        end,
                        author = author,
                        name = name,
                        value = value,
                        ordinal = value,
                    }
                end,
            }),
            previewer = false,
            sorter = telescope_config.generic_sorter(options),
            attach_mappings = function()
                telescope_actions.select_default:replace(_select_book)

                return true
            end,
        })

    return picker
end

--- Run the `:Telescope plugin_template hello-world` command.
---
--- @param options TelescopeCommandOptions The Telescope UI / layout options.
---
function M.get_hello_world_picker(options)

    local function _select_phrases(buffer)
        local phrases = M.get_selection(buffer)

        say_runner.run_say_phrase(phrases)

        telescope_actions.close(buffer)
    end

    local displayer = entry_display.create({
        separator = " ",
        items = { { width = 0.8 }, { remaining = true } },
    })

    -- TODO: Replace with the configuration
    local phrases = { "Hi there!", "Hello, Sailor!", "What's up, doc?" }

    local picker = pickers
        .new(options, {
            prompt_title = "Say Hello",
            finder = finders.new_table({
                results = phrases,
                entry_maker = function(data)
                    return {
                        display = function(entry)
                            return displayer({ entry.value })
                        end,
                        name = data,
                        value = data,
                        ordinal = data,
                    }
                end,
            }),
            previewer = false,
            sorter = telescope_config.generic_sorter(options),
            attach_mappings = function()
                telescope_actions.select_default:replace(_select_phrases)

                return true
            end,
        })

    return picker
end

--- Gather the selected Telescope entries.
---
--- If the user made <Tab> selections, get each of those. If they pressed
--- <CR> without any <Tab> assignments then just get the line that they
--- called <CR> on.
---
--- @param buffer number A 0-or-more value of some Vim buffer.
--- @return string[] # The found selection(s) if any.
---
function M.get_selection(buffer)
    local books = {}

    action_utils.map_selections(buffer, function(selection)
        table.insert(books, selection.value)
    end)

    if not vim.tbl_isempty(books) then
        return books
    end

    local selection = action_state.get_selected_entry()

    if selection ~= nil then
        return { selection.value }
    end

    return {}
end


return M
