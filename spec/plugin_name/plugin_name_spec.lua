local plugin = require("plugin_name")

describe("setup", function()
  it("works with default", function()
    assert(plugin.hello() == "Hello!", "my first function with param = Hello!")
  end)

  it("works with custom var", function()
    -- Quick test
    local buffer = vim.fn.bufnr()
    vim.cmd("buffer " .. tostring(buffer))

    plugin.setup({ opt = "custom" })
    assert(plugin.hello() == "custom", "my first function with param = custom")
  end)
end)