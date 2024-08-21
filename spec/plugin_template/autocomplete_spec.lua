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
end)

describe("simple", function()
    it("works with a basic multi-position example", function()
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
        --
        -- -- NOTE: Beginning a --double-dash named argument, maybe (we don't know yet)
        -- assert.same({"--repeat=", "--style="}, completion.get_options(tree, _parse("say phrase --"), 13))
        -- -- NOTE: Completing the name to a --double-dash named argument
        -- assert.same({"--repeat="}, completion.get_options(tree, _parse("say phrase --r"), 14))
        -- -- -- -- TODO: Figure out how to handle this case later
        -- -- -- -- NOTE: Completing the =, so people know that this is requires an argument
        -- -- -- assert.same({"--repeat="}, completion.get_options(tree, _parse("say phrase --repeat"), 19))
        -- -- NOTE: Completing the value of the named argument
        -- assert.same(
        --     {"1", "2", "3", "4", "5"},
        --     completion.get_options(tree, _parse("say phrase --repeat="), 20)
        -- )
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
        --
        -- assert.same(
        --     {"--style="},
        --     completion.get_options(tree, _parse("say phrase --repeat=5 "), 22)
        -- )
        --
        -- assert.same(
        --     {"--style="},
        --     completion.get_options(tree, _parse("say phrase --repeat=5 --"), 24)
        -- )
        --
        -- assert.same(
        --     {"--style="},
        --     completion.get_options(tree, _parse("say phrase --repeat=5 --s"), 25)
        -- )

        -- -- TODO: Figure out if I'd actually want this. Then implement it if it makes sense to
        -- assert.same(
        --     {"--style="},
        --     completion.get_options(tree, _parse("say phrase --repeat=5 --style"), 29)
        -- )

        -- assert.same(
        --     {"lowercase", "uppercase"},
        --     completion.get_options(tree, _parse("say phrase --repeat=5 --style="), 30)
        -- )

        -- assert.same(
        --     {"lowercase"},
        --     completion.get_options(tree, _parse("say phrase --repeat=5 --style=l"), 31)
        -- )

        -- assert.same(
        --     {},
        --     completion.get_options(tree, _parse("say phrase --repeat=5 --style=lowercase"))
        -- )
    end)
end)

describe("named argument", function()
    it("auto-completes on the dashes - 001", function()
        local tree = {
            {
                argument_type=argparse.ArgumentType.named,
                name="style",
                choices={"lowercase", "uppercase"},
            },
        }

        assert.same({"--style="}, completion.get_options(tree, _parse("-"), 1))
    end)

    it("auto-completes on the dashes - 002", function()
        local tree = {
            {
                argument_type=argparse.ArgumentType.named,
                name="style",
                choices={"lowercase", "uppercase"},
            },
        }

        assert.same({"--style="}, completion.get_options(tree, _parse("--"), 1))
        assert.same({"--style="}, completion.get_options(tree, _parse("--"), 2))
    end)

    it("auto-completes on a partial argument name - 001", function()
        local tree = {
            {
                argument_type=argparse.ArgumentType.named,
                name="style",
                choices={"lowercase", "uppercase"},
            },
        }

        assert.same({"--style="}, completion.get_options(tree, _parse("--s"), 1))
        assert.same({"--style="}, completion.get_options(tree, _parse("--s"), 2))
        assert.same({"--style="}, completion.get_options(tree, _parse("--s"), 3))
    end)

    it("auto-completes on a partial argument name - 002", function()
        local tree = {
            {
                argument_type=argparse.ArgumentType.named,
                name="style",
                choices={"lowercase", "uppercase"},
            },
        }

        assert.same({"--style="}, completion.get_options(tree, _parse("--styl"), 1))
        assert.same({"--style="}, completion.get_options(tree, _parse("--styl"), 2))
        assert.same({"--style="}, completion.get_options(tree, _parse("--styl"), 3))
        assert.same({"--style="}, completion.get_options(tree, _parse("--styl"), 4))
        assert.same({"--style="}, completion.get_options(tree, _parse("--styl"), 5))
        assert.same({"--style="}, completion.get_options(tree, _parse("--styl"), 6))
    end)

    -- -- TODO: Figure out if I'd actually want this. Then implement it if it makes sense to
    -- it("auto-completes on a partial argument name - 003", function()
    --     local tree = {
    --         {
    --             argument_type=argparse.ArgumentType.named,
    --             name="style",
    --             choices={"lowercase", "uppercase"},
    --         },
    --     }
    --
    --     assert.same({"--style="}, completion.get_options(tree, _parse("--style"), 1))
    --     assert.same({"--style="}, completion.get_options(tree, _parse("--style"), 2))
    --     assert.same({"--style="}, completion.get_options(tree, _parse("--style"), 3))
    --     assert.same({"--style="}, completion.get_options(tree, _parse("--style"), 4))
    --     assert.same({"--style="}, completion.get_options(tree, _parse("--style"), 5))
    --     assert.same({"--style="}, completion.get_options(tree, _parse("--style"), 6))
    --     assert.same({"--style="}, completion.get_options(tree, _parse("--style"), 7))
    -- end)

    it("does not auto-complete the name anymore and auto-completes the value", function()
        local tree = {
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
        }

        assert.same({}, completion.get_options(tree, _parse("--style="), 1))
        assert.same({}, completion.get_options(tree, _parse("--style="), 2))
        assert.same({}, completion.get_options(tree, _parse("--style="), 3))
        assert.same({}, completion.get_options(tree, _parse("--style="), 4))
        assert.same({}, completion.get_options(tree, _parse("--style="), 5))
        assert.same({}, completion.get_options(tree, _parse("--style="), 6))
        assert.same({}, completion.get_options(tree, _parse("--style="), 7))
        assert.same({}, completion.get_options(tree, _parse("--style="), 8))
    end)
end)

describe("flag argument", function()
    it("auto-completes on the dash", function()
        local tree = {
            {
                argument_type=argparse.ArgumentType.flag,
                name="f",
            },
        }

        assert.same({"-f"}, completion.get_options(tree, _parse("-"), 1))
    end)

    it("does not auto-complete if at the end of the flag", function()
        local tree = {
            {
                argument_type=argparse.ArgumentType.flag,
                name="f",
            },
        }

        assert.same({}, completion.get_options(tree, _parse("-f"), 1))
        assert.same({}, completion.get_options(tree, _parse("-f"), 2))
    end)

    -- -- TODO: Figure out if I'd actually want this. Then implement it if it makes sense to
    -- it("auto-completes if there's a another flag that can be used", function()
    --     local tree = {
    --         {
    --             argument_type=argparse.ArgumentType.flag,
    --             name="f",
    --         },
    --         {
    --             argument_type=argparse.ArgumentType.flag,
    --             name="a",
    --         },
    --     }
    --
    --     assert.same({}, completion.get_options(tree, _parse("-f"), 1))
    --     assert.same({"a"}, completion.get_options(tree, _parse("-f"), 2))
    -- end)
end)
