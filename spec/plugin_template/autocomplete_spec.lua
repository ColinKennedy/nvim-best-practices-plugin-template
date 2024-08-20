--- Make sure auto-complete works as expected.
---
--- @module 'plugin_template.autocomplete_spec'
---

-- TODO: Move this to a standalone lua module

local argparse = require("plugin_template._cli.argparse")
local completion = require("plugin_template._cli.completion")

local _parse = argparse.parse_arguments

describe("default", function()
    it("works even if #empty #simple", function()
        local tree = {
            "say",
            {"phrase", "word"},
            {
                {
                    choices=function(value)
                        local output = {}
                        value = value or 0

                        for index=1,5 do
                            table.insert(output, value + index)
                        end

                        return output
                    end,
                    name="repeat",
                    argument_type=argparse.ArgumentType.named,
                },
                {
                    argument_type=argparse.ArgumentType.named,
                    name="style",
                    choices={"lowercase", "uppercase"},
                },
            }
        }

        assert.same({}, completion.get_options(tree, _parse(""), 1))
    end)

    it("works with a basic multi-position example #asdf", function()
        local tree = {
            "say",
            {"phrase", "word"},
            {
                {
                    choices=function(value)
                        local output = {}
                        value = value or 0

                        for index=1,5 do
                            table.insert(output, tostring(value + index))
                        end

                        return output
                    end,
                    name="repeat",
                    argument_type=argparse.ArgumentType.named,
                },
                {
                    argument_type=argparse.ArgumentType.named,
                    name="style",
                    choices={"lowercase", "uppercase"},
                },
            }
        }

        -- -- NOTE: Simple examples
        -- assert.same({"say"}, completion.get_options(tree, _parse("sa"), 2))
        -- assert.same({}, completion.get_options(tree, _parse("say"), 3))
        -- assert.same({"phrase", "word"}, completion.get_options(tree, _parse("say "), 4))
        -- assert.same({"phrase"}, completion.get_options(tree, _parse("say p"), 5))
        -- assert.same({}, completion.get_options(tree, _parse("say phrase"), 10))
        -- assert.same({"--repeat=", "--style="}, completion.get_options(tree, _parse("say phrase "), 11))

        -- -- NOTE: Beginning a --double-dash named argument, maybe (we don't know yet)
        -- assert.same({"--repeat=", "--style="}, completion.get_options(tree, _parse("say phrase --"), 13))
        -- -- NOTE: Completing the name to a --double-dash named argument
        -- assert.same({"--repeat="}, completion.get_options(tree, _parse("say phrase --r"), 14))
        -- -- -- TODO: Figure out how to handle this case later
        -- -- -- NOTE: Completing the =, so people know that this is requires an argument
        -- -- assert.same({"--repeat="}, completion.get_options(tree, _parse("say phrase --repeat"), 19))
        -- NOTE: Completing the value of the named argument
        assert.same(
            {"1", "2", "3", "4", "5"},
            completion.get_options(tree, _parse("say phrase --repeat="), 20)
        )
        -- -- NOTE: Completion finished
        -- assert.same(
        --     {},
        --     completion.get_options(tree, _parse("say phrase --repeat=5"), 22)
        -- )
        -- -- NOTE: Asking for repeat again will not show the value (because count == 0)
        -- assert.same(
        --     {},
        --     completion.get_options(tree, _parse("say phrase --repeat=5 --repe"), 30)
        -- )

        -- assert.same(
        --     {"--style="},
        --     completion.get_options(tree, _parse("say phrase --repeat=5 "))
        -- )
        --
        -- assert.same(
        --     {"--style="},
        --     completion.get_options(tree, _parse("say phrase --repeat=5 --"))
        -- )
        --
        -- assert.same(
        --     {"--style="},
        --     completion.get_options(tree, _parse("say phrase --repeat=5 --s"))
        -- )
        --
        -- assert.same(
        --     {"--style="},
        --     completion.get_options(tree, _parse("say phrase --repeat=5 --style"))
        -- )
        --
        -- assert.same(
        --     {"lowercase", "uppercase"},
        --     completion.get_options(tree, _parse("say phrase --repeat=5 --style="))
        -- )
        --
        -- assert.same(
        --     {"lowercase"},
        --     completion.get_options(tree, _parse("say phrase --repeat=5 --style=l"))
        -- )
        --
        -- assert.same(
        --     {},
        --     completion.get_options(tree, _parse("say phrase --repeat=5 --style=lowercase"))
        -- )
    end)
end)
