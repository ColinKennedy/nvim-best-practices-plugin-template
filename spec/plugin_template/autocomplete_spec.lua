--- Make sure auto-complete works as expected.
---
--- @module 'plugin_template.autocomplete_spec'
---

local argparse = require("plugin_template._cli.argparse")
local completion = require("plugin_template._cli.completion")
local configuration = require("plugin_template._core.configuration")

--- @diagnostic disable: undefined-field

local _parse = argparse.parse_arguments

--- @return IncompleteOptionTree # Create a (sparse) tree for unittests.
local function _make_simple_tree()
    local values = {
        {
            choices = function(data)
                local value = data.text

                if value == "" then
                    value = 0
                else
                    value = tonumber(value)

                    if type(value) ~= "number" then
                        return {}
                    end
                end

                --- @cast value number

                local output = {}

                for index = 1, 5 do
                    table.insert(output, tostring(value + index))
                end

                return output
            end,
            name = "repeat",
            argument_type = argparse.ArgumentType.named,
        },
        {
            argument_type = argparse.ArgumentType.named,
            name = "style",
            choices = { "lowercase", "uppercase" },
        },
    }

    return { say = { phrase = values, word = values } }
end

describe("default", function()
    before_each(configuration.initialize_data_if_needed)

    it("works even if #simple", function()
        local tree = _make_simple_tree()

        assert.same({ "say" }, completion.get_options(tree, _parse(""), 1))
    end)
end)

describe("simple", function()
    before_each(configuration.initialize_data_if_needed)

    it("works with multiple position arguments", function()
        local tree = _make_simple_tree()

        assert.same({ "phrase", "word" }, completion.get_options(tree, _parse("say "), 4))
        assert.same({ "--repeat=", "--style=" }, completion.get_options(tree, _parse("say phrase "), 11))
    end)

    it("works with a basic multi-key example", function()
        local values = {
            {
                choices = function(data)
                    local value = data.text

                    if value == "" then
                        value = 0
                    else
                        value = tonumber(value)

                        if type(value) ~= "number" then
                            return {}
                        end
                    end

                    --- @cast value number

                    local output = {}

                    for index = 1, 5 do
                        table.insert(output, tostring(value + index))
                    end

                    return output
                end,
                name = "repeat",
                argument_type = argparse.ArgumentType.named,
            },
            {
                argument_type = argparse.ArgumentType.named,
                name = "style",
                choices = { "lowercase", "uppercase" },
            },
        }

        local tree = { say = { [{ "phrase", "word" }] = values } }

        assert.same({ "--repeat=", "--style=" }, completion.get_options(tree, _parse("say phrase "), 11))
    end)

    it("works even if there is a named / position argument at the same time - 001", function()
        local tree = {
            {
                {
                    argument_type = argparse.ArgumentType.named,
                    name = "style",
                    choices = { "lowercase", "uppercase" },
                },
                {
                    argument_type = argparse.ArgumentType.position,
                    value = "style",
                },
            },
        }

        assert.same({ "--style=", "style" }, completion.get_options(tree, _parse(""), 1))
    end)

    it("works even if there is a named / position argument at the same time - 002", function()
        local tree = {
            {
                {
                    argument_type = argparse.ArgumentType.named,
                    name = "style",
                    choices = { "lowercase", "uppercase" },
                },
                {
                    argument_type = argparse.ArgumentType.position,
                    value = "style",
                },
            },
        }

        assert.same({ "style" }, completion.get_options(tree, _parse("sty"), 3))
        assert.same({ "--style=" }, completion.get_options(tree, _parse("--sty"), 5))
    end)

    it("works with a basic multi-position example", function()
        local tree = _make_simple_tree()

        -- NOTE: Simple examples
        assert.same({ "say" }, completion.get_options(tree, _parse("sa"), 2))
        assert.same({}, completion.get_options(tree, _parse("say"), 3))
        assert.same({ "phrase", "word" }, completion.get_options(tree, _parse("say "), 4))
        assert.same({ "phrase" }, completion.get_options(tree, _parse("say p"), 5))
        assert.same({}, completion.get_options(tree, _parse("say phrase"), 10))
        assert.same({ "--repeat=", "--style=" }, completion.get_options(tree, _parse("say phrase "), 11))

        -- NOTE: Beginning a --double-dash named argument, maybe (we don't know yet)
        assert.same({ "--repeat=", "--style=" }, completion.get_options(tree, _parse("say phrase --"), 13))

        -- NOTE: Completing the name to a --double-dash named argument
        assert.same({ "--repeat=" }, completion.get_options(tree, _parse("say phrase --r"), 14))
        -- NOTE: Completing the =, so people know that this is requires an argument
        assert.same({ "--repeat=" }, completion.get_options(tree, _parse("say phrase --repeat"), 19))
        -- NOTE: Completing the value of the named argument
        assert.same({
            "--repeat=1",
            "--repeat=2",
            "--repeat=3",
            "--repeat=4",
            "--repeat=5",
        }, completion.get_options(tree, _parse("say phrase --repeat="), 20))
        assert.same({
            "--repeat=6",
            "--repeat=7",
            "--repeat=8",
            "--repeat=9",
            "--repeat=10",
        }, completion.get_options(tree, _parse("say phrase --repeat=5"), 22))

        assert.same({ "--style=" }, completion.get_options(tree, _parse("say phrase --repeat=5 "), 22))

        -- NOTE: Asking for repeat again will not show the value (because count == 0)
        assert.same({}, completion.get_options(tree, _parse("say phrase --repeat=5 --repe"), 30))

        assert.same({ "--style=" }, completion.get_options(tree, _parse("say phrase --repeat=5 -"), 23))
        assert.same({ "--style=" }, completion.get_options(tree, _parse("say phrase --repeat=5 --"), 24))

        assert.same({ "--style=" }, completion.get_options(tree, _parse("say phrase --repeat=5 --s"), 25))

        assert.same({ "--style=" }, completion.get_options(tree, _parse("say phrase --repeat=5 --style"), 29))

        assert.same(
            { "--style=lowercase", "--style=uppercase" },
            completion.get_options(tree, _parse("say phrase --repeat=5 --style="), 30)
        )

        assert.same(
            { "--style=lowercase" },
            completion.get_options(tree, _parse("say phrase --repeat=5 --style=l"), 31)
        )

        assert.same({}, completion.get_options(tree, _parse("say phrase --repeat=5 --style=lowercase"), 39))
    end)
end)

describe("named argument", function()
    before_each(configuration.initialize_data_if_needed)

    it("allow named argument as key", function()
        local tree = {
            [{
                argument_type = argparse.ArgumentType.named,
                name = "style",
                choices = { "lowercase", "uppercase" },
            }] = {
                {
                    argument_type = argparse.ArgumentType.position,
                    value = "style",
                },
            },
        }

        assert.same({ "--style=" }, completion.get_options(tree, _parse("--s"), 3))
        assert.same({ "style" }, completion.get_options(tree, _parse("--style=10 "), 11))
        assert.same({}, completion.get_options(tree, _parse("sty"), 3))
    end)

    it("auto-completes on the dashes - 001", function()
        local tree = {
            {
                argument_type = argparse.ArgumentType.named,
                name = "style",
                choices = { "lowercase", "uppercase" },
            },
        }

        assert.same({ "--style=" }, completion.get_options(tree, _parse("-"), 1))
    end)

    it("auto-completes on the dashes - 002", function()
        local tree = {
            {
                argument_type = argparse.ArgumentType.named,
                name = "style",
                choices = { "lowercase", "uppercase" },
            },
        }

        assert.same({ "--style=" }, completion.get_options(tree, _parse("--"), 1))
        assert.same({ "--style=" }, completion.get_options(tree, _parse("--"), 2))
    end)

    it("auto-completes on a #partial argument name - 001", function()
        local tree = {
            {
                argument_type = argparse.ArgumentType.named,
                name = "style",
                choices = { "lowercase", "uppercase" },
            },
        }

        assert.same({ "--style=" }, completion.get_options(tree, _parse("--s"), 1))
        assert.same({ "--style=" }, completion.get_options(tree, _parse("--s"), 2))
        assert.same({ "--style=" }, completion.get_options(tree, _parse("--s"), 3))
    end)

    it("auto-completes on a #partial argument name - 002", function()
        local tree = {
            {
                argument_type = argparse.ArgumentType.named,
                name = "style",
                choices = { "lowercase", "uppercase" },
            },
        }

        assert.same({ "--style=" }, completion.get_options(tree, _parse("--styl"), 1))
        assert.same({ "--style=" }, completion.get_options(tree, _parse("--styl"), 2))
        assert.same({ "--style=" }, completion.get_options(tree, _parse("--styl"), 3))
        assert.same({ "--style=" }, completion.get_options(tree, _parse("--styl"), 4))
        assert.same({ "--style=" }, completion.get_options(tree, _parse("--styl"), 5))
        assert.same({ "--style=" }, completion.get_options(tree, _parse("--styl"), 6))
    end)

    it("auto-completes on a #partial argument name - 003", function()
        local tree = {
            {
                argument_type = argparse.ArgumentType.named,
                name = "style",
                choices = { "lowercase", "uppercase" },
            },
        }

        assert.same({ "--style=" }, completion.get_options(tree, _parse("--style"), 1))
        assert.same({ "--style=" }, completion.get_options(tree, _parse("--style"), 2))
        assert.same({ "--style=" }, completion.get_options(tree, _parse("--style"), 3))
        assert.same({ "--style=" }, completion.get_options(tree, _parse("--style"), 4))
        assert.same({ "--style=" }, completion.get_options(tree, _parse("--style"), 5))
        assert.same({ "--style=" }, completion.get_options(tree, _parse("--style"), 6))
        assert.same({ "--style=" }, completion.get_options(tree, _parse("--style"), 7))
    end)

    it("does not auto-complete the name anymore and auto-completes the value", function()
        local tree = {
            {
                choices = function(data)
                    local output = {}
                    local value = data.value or 0

                    for index = 1, 5 do
                        table.insert(output, tostring(value + index))
                    end

                    return output
                end,
                name = "repeat",
                argument_type = argparse.ArgumentType.named,
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

    it("should only auto-complete --repeat once", function()
        local tree = _make_simple_tree()

        local data = "hello-world say word --repeat= --repe"
        local arguments = argparse.parse_arguments(data)

        assert.same({}, completion.get_options(tree, arguments, 37))
    end)
end)

describe("flag argument", function()
    before_each(configuration.initialize_data_if_needed)

    it("auto-completes on the dash", function()
        local tree = {
            {
                argument_type = argparse.ArgumentType.flag,
                name = "f",
            },
        }

        assert.same({ "-f" }, completion.get_options(tree, _parse("-"), 1))
    end)

    it("does not auto-complete if at the end of the flag", function()
        local tree = {
            {
                argument_type = argparse.ArgumentType.flag,
                name = "f",
            },
        }

        assert.same({}, completion.get_options(tree, _parse("-f"), 1))
        assert.same({}, completion.get_options(tree, _parse("-f"), 2))
    end)
end)
