--- Basic API tests.
---
--- This module is pretty specific to this plugin template so you'll most
--- likely want to delete or heavily modify this file. But it does give a quick
--- look how to mock a test and some things you can do with Neovim/busted.
---
--- @module 'plugin_name.plugin_name_spec'
---

local mock_test = require("mock_test")


describe("hello world commands - say phrase/word", function()
    -- NOTE: We temporarily override vim.inspect so we can grab its
    -- data for unittesting purposes. For most people using this
    -- template, you can remove this text.
    --
    before_each(mock_test.mock_vim_inspect)
    after_each(mock_test.reset_mocked_vim_inspect)

    it("runs hello-world with default arguments", function()
        vim.cmd[[PluginName hello-world say phrase]]

        assert.same({positions={"phrase"}, named={}}, mock_test.get_inspection_data())
    end)

    it("runs hello-world say phrase - with all of its arguments #asdf", function()
        vim.cmd[[PluginName hello-world say phrase "Hello, World!" --repeat=2 --style=lowercase]]

        assert.same(
            {
                positions={"phrase", "Hello, World!"},
                named={["repeat"]="2", style="lowercase"},
            },
            mock_test.get_inspection_data()
        )
    end)

    it("runs hello-world say word - with all of its arguments", function()
        vim.cmd[[PluginName hello-world say word "Hi" --repeat=2 --style=uppercase]]

        assert.same(
            {
                positions={"word", "HI"},
                named={["repeat"]="2", style="uppercase"},
            },
            mock_test.get_inspection_data()
        )
    end)
end)

describe("goodnight-moon commands", function()
    it("runs goodnight-moon read with all of its arguments", function()
        vim.cmd[[PluginName goodnight-moon read]]
        -- TODO: Finish this
    end)

    it("runs goodnight-moon sleep with all of its arguments", function()
        vim.cmd[[PluginName goodnight-moon sleep]]
        -- TODO: Finish this
    end)
end)
