--- Make sure auto-complete works as expected.
---
--- @module 'plugin_template.autocomplete_spec'
---

local argparse = require("plugin_template._cli.argparse")
local completion = require("plugin_template._cli.completion")

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
            option_type = completion.OptionType.named,
        },
        {
            option_type = completion.OptionType.named,
            name = "style",
            choices = { "lowercase", "uppercase" },
        },
    }

    return { say = { phrase = values, word = values } }
end

describe("default", function()
    it("works even if #simple", function()
        local tree = _make_simple_tree()

        assert.same({ "say" }, completion.get_options(tree, _parse(""), 1))
    end)
end)

describe("simple", function()
    it("works with multiple position arguments", function()
        local tree = _make_simple_tree()

        assert.same({ "phrase", "word" }, completion.get_options(tree, _parse("say "), 4))
        assert.same({ "--repeat=", "--style=" }, completion.get_options(tree, _parse("say phrase "), 11))
    end)

    it("works when two positions start with the same text", function()
        local tree = { bottle = { "foo" }, bottles = { "bar" } }

        assert.same({ "bottle", "bottles" }, completion.get_options(tree, _parse("bottle"), 6))
        assert.same({ "foo" }, completion.get_options(tree, _parse("bottle "), 7))
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
                option_type = completion.OptionType.named,
            },
            {
                option_type = completion.OptionType.named,
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
                    option_type = completion.OptionType.named,
                    name = "style",
                    choices = { "lowercase", "uppercase" },
                },
                {
                    option_type = completion.OptionType.position,
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
                    option_type = completion.OptionType.named,
                    name = "style",
                    choices = { "lowercase", "uppercase" },
                },
                {
                    option_type = completion.OptionType.position,
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
        assert.same({ "say" }, completion.get_options(tree, _parse("say"), 3))
        assert.same({ "phrase", "word" }, completion.get_options(tree, _parse("say "), 4))
        assert.same({ "phrase" }, completion.get_options(tree, _parse("say p"), 5))
        assert.same({ "phrase" }, completion.get_options(tree, _parse("say phrase"), 10))
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
    it("allow named argument as key", function()
        local tree = {
            [{
                option_type = completion.OptionType.named,
                name = "style",
                choices = { "lowercase", "uppercase" },
            }] = {
                {
                    option_type = completion.OptionType.position,
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
                option_type = completion.OptionType.named,
                name = "style",
                choices = { "lowercase", "uppercase" },
            },
        }

        assert.same({ "--style=" }, completion.get_options(tree, _parse("-"), 1))
    end)

    it("auto-completes on the dashes - 002", function()
        local tree = {
            {
                option_type = completion.OptionType.named,
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
                option_type = completion.OptionType.named,
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
                option_type = completion.OptionType.named,
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
                option_type = completion.OptionType.named,
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
                option_type = completion.OptionType.named,
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
    it("auto-completes on the dash", function()
        local tree = {
            {
                option_type = completion.OptionType.flag,
                name = "f",
            },
        }

        assert.same({ "-f" }, completion.get_options(tree, _parse("-"), 1))
    end)

    it("does not auto-complete if at the end of the flag", function()
        local tree = {
            {
                option_type = completion.OptionType.flag,
                name = "f",
            },
        }

        assert.same({}, completion.get_options(tree, _parse("-f"), 1))
        assert.same({}, completion.get_options(tree, _parse("-f"), 2))
    end)
end)

describe("numbered count - named argument", function()
    it("works with count = 2", function()
        local tree = {
            {
                option_type = completion.OptionType.named,
                name = "foo",
                choices = { "bar", "fizz", "buzz" },
                count = 2,
            },
        }

        assert.same({ "--foo=" }, completion.get_options(tree, _parse("--fo"), 4))
        assert.same({ "--foo=bar", "--foo=fizz", "--foo=buzz" }, completion.get_options(tree, _parse("--foo="), 6))
        assert.same({ "--foo=" }, completion.get_options(tree, _parse("--foo=bar "), 10))
        assert.same(
            { "--foo=bar", "--foo=fizz", "--foo=buzz" },
            completion.get_options(tree, _parse("--foo=bar --foo="), 16)
        )
        assert.same({}, completion.get_options(tree, _parse("--foo=bar --foo=bar "), 20))
    end)
end)

describe("numbered count - named argument", function()
    it("works with count = 2", function()
        local tree = {
            {
                option_type = completion.OptionType.named,
                name = "foo",
                choices = { "bar", "fizz", "buzz" },
                count = 2,
            },
        }

        assert.same({ "--foo=" }, completion.get_options(tree, _parse("--fo"), 4))
        assert.same({ "--foo=bar", "--foo=fizz", "--foo=buzz" }, completion.get_options(tree, _parse("--foo="), 6))
        assert.same({ "--foo=" }, completion.get_options(tree, _parse("--foo=bar "), 10))
        assert.same(
            { "--foo=bar", "--foo=fizz", "--foo=buzz" },
            completion.get_options(tree, _parse("--foo=bar --foo="), 16)
        )
        assert.same({}, completion.get_options(tree, _parse("--foo=bar --foo=bar "), 20))
    end)
end)

describe("validate arguments", function()
    it("does not error if there is no text and all arguments are optional", function()
        local tree = {
            {
                option_type = argparse.ArgumentType.position,
                required = false,
                name = "foo",
            },
        }

        assert.same({ success = true, messages = {} }, completion.validate_options(tree, _parse("")))
    end)

    it("errors if there is no text and at least one argument is required", function()
        local tree = {
            {
                option_type = argparse.ArgumentType.position,
                required = true,
                name = "foo",
            },
        }

        assert.same(
            { success = false, messages = { "Arguments cannot be empty." } },
            completion.validate_options(tree, _parse(""))
        )
    end)

    it("errors if a named argument is not given a value", function()
        local tree = {
            {
                option_type = argparse.ArgumentType.named,
                name = "foo",
            },
        }

        assert.same(
            { success = false, messages = { 'Named argument "foo" needs a value.' } },
            completion.validate_options(tree, _parse("--foo="))
        )
    end)

    it("errors if a named argument in the middle of parse that is not given a value", function()
        local tree = {
            foo = {
                [{
                    option_type = argparse.ArgumentType.named,
                    name = "bar",
                }] = {
                    {
                        option_type = argparse.ArgumentType.named,
                        name = "fizz",
                    },
                    {
                        option_type = argparse.ArgumentType.named,
                        name = "thing",
                    },
                },
            },
        }

        assert.same(
            { success = false, messages = { 'Named argument "bar" needs a value.' } },
            completion.validate_options(tree, _parse("foo --bar= --fizz=123"))
        )
    end)

    it("errors if a position argument in the middle of parse that is not given a value", function()
        local tree = {
            foo = {
                another = { "blah" },
                bar = {
                    {
                        option_type = argparse.ArgumentType.named,
                        name = "fizz",
                    },
                },
            },
        }

        assert.same(
            { success = false, messages = { 'Missing argument. Need one of: "another, bar".' } },
            completion.validate_options(tree, _parse("foo --fizz "))
        )
    end)

    it("errors if a position argument at the end of a parse that is not given a value", function()
        local tree = {
            foo = {
                another = { "blah" },
                bar = {
                    {
                        option_type = argparse.ArgumentType.named,
                        name = "fizz",
                    },
                },
            },
        }

        assert.same(
            { success = false, messages = { 'Missing argument. Need one of: "blah".' } },
            completion.validate_options(tree, _parse("foo another "))
        )
    end)
end)

describe("* count", function()
    describe("simple", function()
        it("works with position arguments", function()
            local tree = {
                {
                    count = "*",
                    value = "foo",
                    option_type = argparse.ArgumentType.position,
                },
            }

            assert.same({ "foo" }, completion.get_options(tree, _parse(""), 1))
            assert.same({ "foo" }, completion.get_options(tree, _parse("fo"), 2))
            assert.same({ "foo" }, completion.get_options(tree, _parse("foo"), 3))
            assert.same({ "foo" }, completion.get_options(tree, _parse("foo "), 4))
            assert.same({ "foo" }, completion.get_options(tree, _parse("foo fo"), 6))
        end)

        -- TODO: Consider adding this feature later
        -- it("works in the middle of other arguments", function()
        --     local tree = {
        --         foo = {
        --             [
        --                 {
        --                     count = "*",
        --                     name = "bar",
        --                     option_type = argparse.ArgumentType.position,
        --                 }
        --             ] = {"thing", "last"},
        --         }
        --     }
        --
        --     assert.same({ "foo" }, completion.get_options(tree, _parse(""), 1))
        --     assert.same({ "foo" }, completion.get_options(tree, _parse("fo"), 2))
        --     assert.same({ "foo" }, completion.get_options(tree, _parse("foo"), 3))
        --     assert.same({ "foo", "last", "thing" }, completion.get_options(tree, _parse("foo "), 4))
        --     assert.same({ "thing" }, completion.get_options(tree, _parse("foo thi"), 7))
        -- end)
    end)
end)

describe("dynamic argument", function()
    it("skips if no matches were found", function()
        -- TODO: Add
    end)

    it("works even if matches use spaces", function()
        -- TODO: The user's argument should be in quotes, basically
    end)

    it("works with positional arguments #asdf", function()
        local tree = {
            say = {
                [{
                    option_type = argparse.ArgumentType.dynamic,
                    choices = function()
                        return { "a", "bb", "asteroid", "tt" }
                    end,
                }] = { thing = { "another", "last" } },
                [{
                    option_type = argparse.ArgumentType.dynamic,
                    choices = function()
                        return { "ab", "cc", "zzz", "lazers" }
                    end,
                }] = { different = { "branch", "here" } },
            },
        }

        assert.same(
            { "a", "ab", "asteroid", "bb", "cc", "lazers", "tt", "zzz" },
            completion.get_options(tree, _parse("say "), 4)
        )
        assert.same({ "a", "ab", "asteroid" }, completion.get_options(tree, _parse("say a"), 5))
        assert.same({ "thing" }, completion.get_options(tree, _parse("say a "), 6))
        assert.same({ "another", "last" }, completion.get_options(tree, _parse("say a thing "), 12))

        assert.same({ "a", "ab", "asteroid" }, completion.get_options(tree, _parse("say a"), 5))
        assert.same({ "different" }, completion.get_options(tree, _parse("say ab "), 7))
        assert.same({ "branch", "here" }, completion.get_options(tree, _parse("say ab different "), 17))
    end)

    it("works with count = 2", function()
        -- TODO: Add
    end)
end)
