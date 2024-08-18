--- Make sure the argument parser works as expected.
---
--- @module 'plugin_name.argparse_spec'
---

-- TODO: Consider moving this to a different branch in the repo or move the
-- whole argparse into a different Lua project
local argparse = require("plugin_name._cli.argparse")

describe("default", function()
    it("works even if #empty #simple", function()
        assert.same({arguments={}, remainder={value=""}}, argparse.parse_args(""))
    end)
end)

describe("positional arguments", function()
    it("#simple single argument", function()
        assert.same(
            {arguments={{argument_type=argparse.ArgumentType.position, value="foo"}}, remainder={value=""}},
            argparse.parse_args("foo")
        )
    end)

    it("#simple multiple arguments", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.position, value="foo"},
                    {argument_type=argparse.ArgumentType.position, value="bar"},
                },
                remainder = {value=""},
            },
            argparse.parse_args("foo bar")
        )
    end)

    it("#escaped positional arguments 001", function()
        assert.same(
            {arguments={{argument_type=argparse.ArgumentType.position, value="foo "}}, remainder={value=""}},
            argparse.parse_args("foo\\ ")
        )
    end)

    it("#escaped positional arguments 002", function()
        assert.same(
            {arguments={{argument_type=argparse.ArgumentType.position, value="foo bar"}}, remainder={value=""}},
            argparse.parse_args("foo\\ bar")
        )
    end)
end)

describe("quotes", function()
    it("quoted positional arguments", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.position, value="foo"},
                    {argument_type=argparse.ArgumentType.position, value="bar fizz buzz"},
                },
                remainder={value=""},
            },
            argparse.parse_args('foo "bar fizz buzz"')
        )
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.position, value="bar fizz buzz"},
                    {argument_type=argparse.ArgumentType.position, value="foo"},
                },
                remainder = {value=""},
            },
            argparse.parse_args('"bar fizz buzz" foo')
        )
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.position, value="foo"},
                    {argument_type=argparse.ArgumentType.position, value="bar fizz"},
                    {argument_type=argparse.ArgumentType.position, value="buzz"},
                },
                remainder = {value=""},
            },
            argparse.parse_args('foo "bar fizz" buzz')
        )
    end)

    it("flags within the quotes", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.position, value="foo"},
                    {argument_type=argparse.ArgumentType.position, value="bar -f --fizz"},
                },
                remainder = {value=""},
            },
            argparse.parse_args("foo 'bar -f --fizz'")
        )
    end)

    it("#multiple arguments", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.position, value="foo"},
                    {argument_type=argparse.ArgumentType.position, value="bar"},
                },
                remainder = {value=""},
            },
            argparse.parse_args("foo bar")
        )
    end)

    it("#escaped spaces 001", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.position, value="foo "},
                },
                remainder = {value=""},
            },
            argparse.parse_args("foo\\ ")
        )
    end)

    it("#escaped spaces 002", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.position, value="foo bar"},
                },
                remainder = {value=""},
            },
            argparse.parse_args("foo\\ bar")
        )
    end)
end)

describe("double-dash flags", function()
    it("mixed --flag", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.flag, name="foo-bar"},
                    {argument_type=argparse.ArgumentType.flag, name="fizz"},
                },
                remainder = {value=""},
            },
            argparse.parse_args("--foo-bar --fizz")
        )
    end)

    it("single --flag", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.flag, name="foo-bar"},
                },
                remainder = {value=""},
            },
            argparse.parse_args("--foo-bar")
        )
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.flag, name="foo"},
                },
                remainder = {value=""},
            },
            argparse.parse_args("--foo")
        )
    end)

    it("multiple", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.flag, name="foo"},
                    {argument_type=argparse.ArgumentType.flag, name="bar"},
                    {argument_type=argparse.ArgumentType.flag, name="fizz"},
                    {argument_type=argparse.ArgumentType.flag, name="buzz"},
                },
                remainder = {value=""},
            },
            argparse.parse_args("--foo --bar --fizz --buzz")
        )
    end)
end)

describe("double-dash equal-flags", function()
    it("mixed --flag", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.flag, name="foo-bar"},
                    {argument_type=argparse.ArgumentType.flag, name="fizz"},
                },
                remainder = {value=""},
            },
            argparse.parse_args("--foo-bar --fizz")
        )
    end)

    it("single --flag", function()
        assert.same(
            {
                arguments={{argument_type=argparse.ArgumentType.flag, name="foo-bar"}},
                remainder = {value=""},
            },
            argparse.parse_args("--foo-bar")
        )
        assert.same(
            {arguments={{argument_type=argparse.ArgumentType.flag, name="foo"}}, remainder={value=""}},
            argparse.parse_args("--foo")
        )
    end)

    it("multiple", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.named, name="foo", value="text"},
                    {argument_type=argparse.ArgumentType.named, name="bar", value="some thing"},
                    {argument_type=argparse.ArgumentType.flag, name="fizz"},
                    {argument_type=argparse.ArgumentType.named, name="buzz", value="blah"},
                },
                remainder = {value=""},
            },
            argparse.parse_args("--foo='text' --bar=\"some thing\" --fizz --buzz='blah'")
        )
    end)
end)

describe("single-dash flags", function()
    it("single", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.flag, name="f"},
                },
                remainder = {value=""},
            },
            argparse.parse_args("-f")
        )
    end)

    it("multiple, combined", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.flag, name="f"},
                    {argument_type=argparse.ArgumentType.flag, name="b"},
                    {argument_type=argparse.ArgumentType.flag, name="z"},
                },
                remainder = {value=""},
            },
            argparse.parse_args("-fbz")
        )
    end)

    it("multiple, separate", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.flag, name="f"},
                    {argument_type=argparse.ArgumentType.flag, name="b"},
                    {argument_type=argparse.ArgumentType.flag, name="z"},
                },
                remainder = {value=""},
            },
            argparse.parse_args("-f -b -z")
        )
    end)
end)

describe("remainder - positions", function()
    it("keeps track of single position text", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.position, value="foo"},
                },
                remainder = {value=" "},
            },
            argparse.parse_args("foo ")
        )
    end)

    it("keeps track of multiple position text", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.position, value="foo"},
                    {argument_type=argparse.ArgumentType.position, value="bar"},
                },
                remainder = {value="  "},
            },
            argparse.parse_args("foo bar  ")
        )
    end)
end)

describe("remainder - flags", function()
    it("keeps track of flag text - 001", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.flag, name="f"},
                    {argument_type=argparse.ArgumentType.flag, name="b"},
                    {argument_type=argparse.ArgumentType.flag, name="z"},
                },
                remainder = {value=" -"},
            },
            argparse.parse_args("-f -b -z -")
        )
    end)

    it("keeps track of flag text - 002", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.flag, name="f"},
                    {argument_type=argparse.ArgumentType.flag, name="b"},
                    {argument_type=argparse.ArgumentType.flag, name="z"},
                },
                remainder = {value=" --"},
            },
            argparse.parse_args("-f -b -z --")
        )
    end)

    it("keeps track of flag text - 003", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.flag, name="f"},
                    {argument_type=argparse.ArgumentType.flag, name="b"},
                    {argument_type=argparse.ArgumentType.flag, name="z"},
                    {argument_type=argparse.ArgumentType.flag, name="r"},
                },
                remainder = {value=""},
            },
            argparse.parse_args("-f -b -z --r")
        )
    end)

    it("sees spaces when no arguments are given", function()
        assert.same(
            { arguments = {}, remainder = {value="    "} },
            argparse.parse_args("    ")
        )
    end)

    it("stores the last space(s) - multiple", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.flag, name="f"},
                    {argument_type=argparse.ArgumentType.flag, name="b"},
                    {argument_type=argparse.ArgumentType.flag, name="z"},
                },
                remainder = {value="  "},
            },
            argparse.parse_args("-f -b -z  ")
        )
    end)

    it("stores the last space(s) - single", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.flag, name="f"},
                    {argument_type=argparse.ArgumentType.flag, name="b"},
                    {argument_type=argparse.ArgumentType.flag, name="z"},
                },
                remainder = {value=" "},
            },
            argparse.parse_args("-f -b -z ")
        )
    end)

    it("stores the last space(s) - combined", function()
        assert.same(
            {
                arguments = {
                    {argument_type=argparse.ArgumentType.flag, name="f"},
                    {argument_type=argparse.ArgumentType.flag, name="b"},
                    {argument_type=argparse.ArgumentType.flag, name="x"},
                    {argument_type=argparse.ArgumentType.flag, name="y"},
                    {argument_type=argparse.ArgumentType.flag, name="z"},
                },
                remainder = {value=" "},
            },
            argparse.parse_args("-f -b -xyz ")
        )
    end)
end)
