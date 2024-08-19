--- Basic API tests.
---
--- This module is pretty specific to this plugin template so you'll most
--- likely want to delete or heavily modify this file. But it does give a quick
--- look how to mock a test and some things you can do with Neovim/busted.
---
--- @module 'plugin_template.plugin_template_spec'
---

local mock_test = require("test_utilities.mock_test")
local say_command = require("plugin_template._commands.say.command")

_DATA = {}
_ORIGINAL_PRINTER = print
_ORIGINAL_SAY_PRINTER = say_command._print

local function _save_prints(data)
    table.insert(_DATA, data)
end

local function _clear_saved_prints()
    say_command._print = _ORIGINAL_SAY_PRINTER
    _DATA = {}
end

describe("hello world commands - say phrase/word", function()
    -- NOTE: We temporarily override vim.inspect so we can grab its
    -- data for unittesting purposes. For most people using this
    -- template, you can remove this text.
    --
    before_each(function()
        say_command._print = _save_prints
        print = function(...) end  -- Silence all prints
    end)
    after_each(function()
        print = _ORIGINAL_PRINTER
        _clear_saved_prints()
    end)

    it("runs hello-world with default arguments", function()
        vim.cmd[[PluginTemplate hello-world say phrase]]

        assert.same({""}, _DATA)
    end)

    it("runs hello-world say phrase - with all of its arguments", function()
        vim.cmd[[PluginTemplate hello-world say phrase "Hello, World!" --repeat=2 --style=lowercase]]

        assert.same({"hello, world!", "hello, world!"}, _DATA)
    end)

    it("runs hello-world say word - with all of its arguments", function()
        vim.cmd[[PluginTemplate hello-world say word "Hi" --repeat=2 --style=uppercase]]

        assert.same({"HI", "HI"}, _DATA)
    end)
end)

-- TODO: Implement Goodnight moon
-- describe("goodnight-moon commands", function()
--     it("runs goodnight-moon read with all of its arguments", function()
--         vim.cmd[[PluginTemplate goodnight-moon read]]
--         -- TODO: Finish this
--     end)
--
--     it("runs goodnight-moon sleep with all of its arguments", function()
--         vim.cmd[[PluginTemplate goodnight-moon sleep]]
--         -- TODO: Finish this
--     end)
-- end)
