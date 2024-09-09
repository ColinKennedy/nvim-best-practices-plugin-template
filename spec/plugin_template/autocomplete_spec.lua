--- Make sure auto-complete works as expected.
---
--- @module 'plugin_template.autocomplete_spec'
---

local argparse = require("plugin_template._cli.argparse")
local argparse2 = require("plugin_template._cli.argparse2")
local completion = require("plugin_template._cli.completion")

-- TODO: Docstring

--- @diagnostic disable: undefined-field

local _parse = argparse.parse_arguments

--- @return ArgumentParser # Create a tree of commands for unittests.
local function _make_simple_parser()
    local choices = function(data)
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
    end

    local parser = argparse2.ArgumentParser.new({name="test", description="Test"})
    local subparsers = parser:add_subparsers({destination="commands"})
    local say = subparsers:add_parser({name="say", description="Print stuff to the terminal."})
    local say_subparsers = say:add_subparsers({destination="say_commands", description="All commands that print."})
    local say_word = say_subparsers:add_parser({name="word", description="Print a single word."})
    local say_phrase = say_subparsers:add_parser({name="phrase", description="Print a whole sentence."})

    say_word:add_argument({names={"--repeat"}, choices=choices, description="The number of times to repeat the word"})
    say_phrase:add_argument({names={"--repeat"}, choices=choices, description="The number of times to repeat the phrase."})

    return parser
end

--- @return ArgumentParser # Create a tree of commands for unittests.
local function _make_style_parser()
    local parser = argparse2.ArgumentParser.new({name="test", description="Test"})
    local choice = { "lowercase", "uppercase" }
    parser:add_argument({names="--style", choices=choice, description="Define how to print to the terminal", destination="style_flag"})
    parser:add_argument({names="style", description="Define how to print to the terminal", destination="style_position"})

    return parser
end


describe("default", function()
    it("works even if #simple", function()
        local parser = _make_simple_parser()

        assert.same({ "say" }, parser:get_completion(""))
    end)
end)

describe("simple", function()
    it("works with multiple position arguments", function()
        local parser = _make_simple_parser()

        assert.same({ "say" }, parser:get_completion("sa"))
        assert.same({ "say" }, parser:get_completion("say"))
        assert.same({ "phrase", "word" }, parser:get_completion("say "))
        assert.same({ "--repeat=", "--style=" }, parser:get_completion("say phrase "))
    end)

    it("works when two positions start with the same text", function()
        local parser = { bottle = { "foo" }, bottles = { "bar" } }

        assert.same({ "bottle", "bottles" }, parser:get_completion("bottle"))
        assert.same({ "foo" }, parser:get_completion("bottle "))
    end)

    it("works with a basic multi-key example", function()
        local parser = _make_simple_parser()

        assert.same({ "--repeat=", "--style=" }, parser:get_completion("say phrase "))
    end)

    it("works even if there is a named / position argument at the same time - 001", function()
        local parser = _make_style_parser()

        assert.same({ "--style=" }, parser:get_completion(""))
        assert.same({}, parser:get_completion("foo"))
    end)

    it("works even if there is a named / position argument at the same time - 002", function()
        local parser = {
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

        assert.same({ "style" }, parser:get_completion("sty"))
        assert.same({ "--style=" }, parser:get_completion("--sty"))
    end)

    it("works with a basic multi-position example", function()
        local parser = _make_simple_parser()

        -- NOTE: Simple examples
        assert.same({ "say" }, parser:get_completion("sa"))
        assert.same({ "say" }, parser:get_completion("say"))
        assert.same({ "phrase", "word" }, parser:get_completion("say "))
        assert.same({ "phrase" }, parser:get_completion("say p"))
        assert.same({ "phrase" }, parser:get_completion("say phrase"))
        assert.same({ "--repeat=", "--style=" }, parser:get_completion("say phrase "))

        -- NOTE: Beginning a --double-dash named argument, maybe (we don't know yet)
        assert.same({ "--repeat=", "--style=" }, parser:get_completion("say phrase --"))

        -- NOTE: Completing the name to a --double-dash named argument
        assert.same({ "--repeat=" }, parser:get_completion("say phrase --r"))
        -- NOTE: Completing the =, so people know that this is requires an argument
        assert.same({ "--repeat=" }, parser:get_completion("say phrase --repeat"))
        -- NOTE: Completing the value of the named argument
        assert.same({
            "--repeat=1",
            "--repeat=2",
            "--repeat=3",
            "--repeat=4",
            "--repeat=5",
        }, parser:get_completion("say phrase --repeat="))
        assert.same({
            "--repeat=6",
            "--repeat=7",
            "--repeat=8",
            "--repeat=9",
            "--repeat=10",
        }, parser:get_completion("say phrase --repeat=5"))

        assert.same({ "--style=" }, parser:get_completion("say phrase --repeat=5 "))

        -- NOTE: Asking for repeat again will not show the value (because count == 0)
        assert.same({}, parser:get_completion("say phrase --repeat=5 --repe"))

        assert.same({ "--style=" }, parser:get_completion("say phrase --repeat=5 -"))
        assert.same({ "--style=" }, parser:get_completion("say phrase --repeat=5 --"))

        assert.same({ "--style=" }, parser:get_completion("say phrase --repeat=5 --s"))

        assert.same({ "--style=" }, parser:get_completion("say phrase --repeat=5 --style"))

        assert.same(
            { "--style=lowercase", "--style=uppercase" },
            parser:get_completion("say phrase --repeat=5 --style=")
        )

        assert.same(
            { "--style=lowercase" },
            parser:get_completion("say phrase --repeat=5 --style=l")
        )

        assert.same({}, parser:get_completion("say phrase --repeat=5 --style=lowercase"))
    end)
end)

describe("named argument", function()
    it("allow named argument as key", function()
        local parser = {
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

        assert.same({ "--style=" }, parser:get_completion("--s"))
        assert.same({ "style" }, parser:get_completion("--style=10 "))
        assert.same({}, parser:get_completion("sty"))
    end)

    -- TODO: Fix at some point
    -- it("auto-completes on the dashes - 001", function()
    --     local parser = {
    --         {
    --             option_type = completion.OptionType.named,
    --             name = "style",
    --             choices = { "lowercase", "uppercase" },
    --         },
    --     }
    --
    --     assert.same({ "--style=" }, parser:get_completion("-"), 1))
    -- end)
    --
    -- it("auto-completes on the dashes - 002", function()
    --     local parser = {
    --         {
    --             option_type = completion.OptionType.named,
    --             name = "style",
    --             choices = { "lowercase", "uppercase" },
    --         },
    --     }
    --
    --     assert.same({ "--style=" }, parser:get_completion("--"), 1))
    --     assert.same({ "--style=" }, parser:get_completion("--"), 2))
    -- end)

    it("auto-completes on a #partial argument name - 001", function()
        local parser = {
            {
                option_type = completion.OptionType.named,
                name = "style",
                choices = { "lowercase", "uppercase" },
            },
        }

        assert.same({ "--style=" }, parser:get_completion("--s", 1))
        assert.same({ "--style=" }, parser:get_completion("--s", 2))
        assert.same({ "--style=" }, parser:get_completion("--s", 3))
    end)

    it("auto-completes on a #partial argument name - 002", function()
        local parser = {
            {
                option_type = completion.OptionType.named,
                name = "style",
                choices = { "lowercase", "uppercase" },
            },
        }

        assert.same({ "--style=" }, parser:get_completion("--styl", 1))
        assert.same({ "--style=" }, parser:get_completion("--styl", 2))
        assert.same({ "--style=" }, parser:get_completion("--styl", 3))
        assert.same({ "--style=" }, parser:get_completion("--styl", 4))
        assert.same({ "--style=" }, parser:get_completion("--styl", 5))
        assert.same({ "--style=" }, parser:get_completion("--styl", 6))
    end)

    it("auto-completes on a #partial argument name - 003", function()
        local parser = {
            {
                option_type = completion.OptionType.named,
                name = "style",
                choices = { "lowercase", "uppercase" },
            },
        }

        assert.same({ "--style=" }, parser:get_completion("--style", 1))
        assert.same({ "--style=" }, parser:get_completion("--style", 2))
        assert.same({ "--style=" }, parser:get_completion("--style", 3))
        assert.same({ "--style=" }, parser:get_completion("--style", 4))
        assert.same({ "--style=" }, parser:get_completion("--style", 5))
        assert.same({ "--style=" }, parser:get_completion("--style", 6))
        assert.same({ "--style=" }, parser:get_completion("--style", 7))
    end)

    it("does not auto-complete the name anymore and auto-completes the value", function()
        local parser = {
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

        assert.same({}, parser:get_completion("--style=", 1))
        assert.same({}, parser:get_completion("--style=", 2))
        assert.same({}, parser:get_completion("--style=", 3))
        assert.same({}, parser:get_completion("--style=", 4))
        assert.same({}, parser:get_completion("--style=", 5))
        assert.same({}, parser:get_completion("--style=", 6))
        assert.same({}, parser:get_completion("--style=", 7))
        assert.same({}, parser:get_completion("--style=", 8))
    end)

    it("should only auto-complete --repeat once", function()
        local parser = _make_simple_parser()

        local data = "hello-world say word --repeat= --repe"
        local arguments = argparse.parse_arguments(data)

        assert.same({}, completion.get_options(parser, arguments))
    end)
end)

describe("flag argument", function()
    -- TODO: Implement this later
    -- it("auto-completes on the dash", function()
    --     local parser = {
    --         {
    --             option_type = completion.OptionType.flag,
    --             name = "f",
    --         },
    --     }
    --
    --     assert.same({ "-f" }, parser:get_completion("-"), 1))
    -- end)

    it("does not auto-complete if at the end of the flag", function()
        local parser = {
            {
                option_type = completion.OptionType.flag,
                name = "f",
            },
        }

        assert.same({}, parser:get_completion("-f", 1))
        assert.same({}, parser:get_completion("-f", 2))
    end)
end)

describe("numbered count - named argument", function()
    it("works with count = 2", function()
        local parser = {
            {
                option_type = completion.OptionType.named,
                name = "foo",
                choices = { "bar", "fizz", "buzz" },
                count = 2,
            },
        }

        assert.same({ "--foo=" }, parser:get_completion("--fo"))
        assert.same({ "--foo=bar", "--foo=fizz", "--foo=buzz" }, parser:get_completion("--foo="))
        assert.same({ "--foo=" }, parser:get_completion("--foo=bar "))
        assert.same(
            { "--foo=bar", "--foo=fizz", "--foo=buzz" },
            parser:get_completion("--foo=bar --foo=")
        )
        assert.same({}, parser:get_completion("--foo=bar --foo=bar "))
    end)
end)

describe("numbered count - named argument", function()
    it("works with count = 2", function()
        local parser = {
            {
                option_type = completion.OptionType.named,
                name = "foo",
                choices = { "bar", "fizz", "buzz" },
                count = 2,
            },
        }

        assert.same({ "--foo=" }, parser:get_completion("--fo"))
        assert.same({ "--foo=bar", "--foo=fizz", "--foo=buzz" }, parser:get_completion("--foo="))
        assert.same({ "--foo=" }, parser:get_completion("--foo=bar "))
        assert.same(
            { "--foo=bar", "--foo=fizz", "--foo=buzz" },
            parser:get_completion("--foo=bar --foo=")
        )
        assert.same({}, parser:get_completion("--foo=bar --foo=bar "))
    end)
end)

describe("validate arguments", function()
    it("does not error if there is no text and all arguments are optional", function()
        local parser = {
            {
                option_type = argparse.ArgumentType.position,
                required = false,
                name = "foo",
            },
        }

        assert.same({ success = true, messages = {} }, completion.validate_options(parser, _parse("")))
    end)

    it("errors if there is no text and at least one argument is required", function()
        local parser = {
            {
                option_type = argparse.ArgumentType.position,
                required = true,
                name = "foo",
            },
        }

        assert.same(
            { success = false, messages = { "Arguments cannot be empty." } },
            completion.validate_options(parser, _parse(""))
        )
    end)

    it("errors if a named argument is not given a value", function()
        local parser = {
            {
                option_type = argparse.ArgumentType.named,
                name = "foo",
            },
        }

        assert.same(
            { success = false, messages = { 'Named argument "foo" needs a value.' } },
            completion.validate_options(parser, _parse("--foo="))
        )
    end)

    it("errors if a named argument in the middle of parse that is not given a value", function()
        local parser = {
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
            completion.validate_options(parser, _parse("foo --bar= --fizz=123"))
        )
    end)

    it("errors if a position argument in the middle of parse that is not given a value", function()
        local parser = {
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
            completion.validate_options(parser, _parse("foo --fizz "))
        )
    end)

    it("errors if a position argument at the end of a parse that is not given a value", function()
        local parser = {
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
            completion.validate_options(parser, _parse("foo another "))
        )
    end)
end)

describe("* count", function()
    describe("simple", function()
        it("works with position arguments", function()
            local parser = {
                {
                    count = "*",
                    value = "foo",
                    option_type = argparse.ArgumentType.position,
                },
            }

            assert.same({ "foo" }, parser:get_completion(""))
            assert.same({ "foo" }, parser:get_completion("fo"))
            assert.same({ "foo" }, parser:get_completion("foo"))
            assert.same({ "foo" }, parser:get_completion("foo "))
            assert.same({ "foo" }, parser:get_completion("foo fo"))
        end)
    end)
end)

describe("dynamic argument", function()
    it("skips if no matches were found", function()
        -- TODO: Add
    end)

    it("works even if matches use spaces", function()
        -- TODO: The user's argument should be in quotes, basically
    end)

    it("works with positional arguments", function()
        local parser = {
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
            parser:get_completion("say ")
        )
        assert.same({ "a", "ab", "asteroid" }, parser:get_completion("say a"))
        assert.same({ "thing" }, parser:get_completion("say a "))
        assert.same({ "another", "last" }, parser:get_completion("say a thing "))

        assert.same({ "a", "ab", "asteroid" }, parser:get_completion("say a"))
        assert.same({ "different" }, parser:get_completion("say ab "))
        assert.same({ "branch", "here" }, parser:get_completion("say ab different "))
    end)

    it("works with count = 2", function()
        -- TODO: Add
    end)
end)
