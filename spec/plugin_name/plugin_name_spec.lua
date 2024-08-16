describe("hello world commands - say phrase/word", function()
    it("runs hello world with default arguments", function()
        vim.cmd[[PluginName hello-world say phrase]]
        -- TODO: Finish this
    end)

    it("runs hello world with all of its arguments", function()
        vim.cmd[[PluginName hello-world say phrase "Hello, World!" --repeat=2 --style=lowercase]]
        -- TODO: Finish this
    end)

    -- TODO: Add `word` example
end)

describe("goodnight moon commands", function()
    it("runs goodnight-moon read with all of its arguments", function()
        vim.cmd[[PluginName goodnight-moon read]]
        -- TODO: Finish this
    end)

    it("runs goodnight-moon sleep with all of its arguments", function()
        vim.cmd[[PluginName goodnight-moon sleep]]
        -- TODO: Finish this
    end)
end)
