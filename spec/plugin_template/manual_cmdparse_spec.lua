--- Make sure that the old, manual way of setting up cmdparse also works.
---
---@module 'plugin_template.manual_cmdparse_spec'
---

local cli_subcommand = require("plugin_template._cli.cli_subcommand")

describe("complete", function()
    it("completes with a basic parser", function()
        local completer = cli_subcommand.make_subcommand_completer("Foo", {
            some_subcommand = {
                complete = function(data)
                    return data.input
                end,
            },
        })

        assert.same({ "some_subcommand" }, completer("some_sub", "Foo some_subcommand lines here"))
    end)
end)

describe("run", function()
    it("parses and runs some fake code", function()
        local arguments = nil

        local triager = cli_subcommand.make_subcommand_triager({
            some_subcommand = {
                run = function(data)
                    arguments = data.input.arguments
                end,
            },
        })

        triager({ fargs = { "some_subcommand" }, args = "some_subcommand more stuff" })

        assert.same({
            {
                argument_type = "__position",
                range = {
                    end_column = 4,
                    start_column = 1,
                },
                value = "more",
            },
            {
                argument_type = "__position",
                range = {
                    end_column = 10,
                    start_column = 6,
                },
                value = "stuff",
            },
        }, arguments)
    end)
end)
