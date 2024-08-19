--- Make sure the argument parser works as expected.
---
--- @module 'plugin_name.argparse_spec'
---

-- TODO: Consider moving this to a different branch in the repo or move the
-- whole argparse into a different Lua project
local argparse = require("plugin_name._cli.argparse")

describe("default", function()
    it("works even if #empty #simple", function()
        assert.same({arguments={}, remainder={value=""}}, argparse.parse_arguments(""))
    end)
end)

describe("positional arguments", function()
    it("#simple single argument", function()
        assert.same(
            {
                arguments={
                    {
                        argument_type=argparse.ArgumentType.position,
                        range="1,3",
                        value="foo",
                    },
                },
                remainder={value=""},
            },
            argparse.parse_arguments("foo")
        )
    end)

    it("#simple multiple arguments", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.position,
                        range="1,3",
                        value="foo",
                    },
                    {
                        argument_type=argparse.ArgumentType.position,
                        range="5,7",
                        value="bar",
                    },
                },
                remainder = {value=""},
            },
            argparse.parse_arguments("foo bar")
        )
    end)

    it("#escaped positional arguments 001", function()
        assert.same(
            {
                arguments={
                    {
                        argument_type=argparse.ArgumentType.position,
                        range="1,4",
                        value="foo ",
                    },
                },
                remainder={value=""},
            },
            argparse.parse_arguments("foo\\ ")
        )
    end)

    it("#escaped positional arguments 002", function()
        assert.same(
            {
                arguments={
                    {
                        argument_type=argparse.ArgumentType.position,
                        range="1,7",
                        value="foo bar",
                    },
                },
                remainder={value=""},
            },
            argparse.parse_arguments("foo\\ bar")
        )
    end)
end)

describe("quotes", function()
    it("quoted positional arguments", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.position,
                        range="1,3",
                        value="foo",
                    },
                    {
                        argument_type=argparse.ArgumentType.position,
                        range="5,19",
                        value="bar fizz buzz",
                    },
                },
                remainder={value=""},
            },
            argparse.parse_arguments('foo "bar fizz buzz"')
        )
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.position,
                        range="1,15",
                        value="bar fizz buzz",
                    },
                    {
                        argument_type=argparse.ArgumentType.position,
                        range="17,19",
                        value="foo",
                    },
                },
                remainder = {value=""},
            },
            argparse.parse_arguments('"bar fizz buzz" foo')
        )
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.position,
                        range="1,3",
                        value="foo",
                    },
                    {
                        argument_type=argparse.ArgumentType.position,
                        range="5,14",
                        value="bar fizz",
                    },
                    {
                        argument_type=argparse.ArgumentType.position,
                        range="16,19",
                        value="buzz",
                    },
                },
                remainder = {value=""},
            },
            argparse.parse_arguments('foo "bar fizz" buzz')
        )
    end)

    it("flags within the quotes #asdf", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.position,
                        range="1,3",
                        value="foo",
                    },
                    {
                        argument_type=argparse.ArgumentType.position,
                        range="5,19",
                        value="bar -f --fizz",
                    },
                },
                remainder = {value=""},
            },
            argparse.parse_arguments("foo 'bar -f --fizz'")
        )
    end)

    it("#multiple arguments", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.position,
                        range="1,3",
                        value="foo",
                    },
                    {
                        argument_type=argparse.ArgumentType.position,
                        range="5,7",
                        value="bar",
                    },
                },
                remainder = {value=""},
            },
            argparse.parse_arguments("foo bar")
        )
    end)

    it("#escaped spaces 001", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.position,
                        value="foo ",
                        range="1,4",
                    },
                },
                remainder = {value=""},
            },
            argparse.parse_arguments("foo\\ ")
        )
    end)

    it("#escaped spaces 002", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.position,
                        value="foo bar",
                        range="1,7",
                    },
                },
                remainder = {value=""},
            },
            argparse.parse_arguments("foo\\ bar")
        )
    end)
end)

describe("double-dash flags", function()
    it("mixed --flag", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="foo-bar",
                        range="1,9",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="fizz",
                        range="11,16",
                    },
                },
                remainder = {value=""},
            },
            argparse.parse_arguments("--foo-bar --fizz")
        )
    end)

    it("single --flag", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="foo-bar",
                        range="1,9",
                    },
                },
                remainder = {value=""},
            },
            argparse.parse_arguments("--foo-bar")
        )
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="foo",
                        range="1,5",
                    },
                },
                remainder = {value=""},
            },
            argparse.parse_arguments("--foo")
        )
    end)

    it("multiple", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="foo",
                        range="1,5",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="bar",
                        range="7,11",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="fizz",
                        range="13,18",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="buzz",
                        range="20,25",
                    },
                },
                remainder = {value=""},
            },
            argparse.parse_arguments("--foo --bar --fizz --buzz")
        )
    end)

    it("partial --flag=", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.named,
                        name="foo-bar",
                        value = false,
                        range="1,10",
                    },
                },
                remainder = {value=""},
            },
            argparse.parse_arguments("--foo-bar=")
        )
    end)
end)

describe("double-dash equal-flags", function()
    it("mixed --flag", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="foo-bar",
                        range="1,9",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="fizz",
                        range="11,16",
                    },
                },
                remainder = {value=""},
            },
            argparse.parse_arguments("--foo-bar --fizz")
        )
    end)

    it("single --flag", function()
        assert.same(
            {
                arguments={
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="foo-bar",
                        range="1,9",
                    },
                },
                remainder = {value=""},
            },
            argparse.parse_arguments("--foo-bar")
        )
        assert.same(
            {
                arguments={
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="foo",
                        range="1,5",
                    },
                },
                remainder={value=""},
            },
            argparse.parse_arguments("--foo")
        )
    end)

    it("multiple", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.named,
                        name="foo",
                        range="1,12",
                        value="text",
                    },
                    {
                        argument_type=argparse.ArgumentType.named,
                        name="bar",
                        range="14,31",
                        value="some thing",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="fizz",
                        range="33,38",
                    },
                    {
                        argument_type=argparse.ArgumentType.named,
                        name="buzz",
                        range="40,52",
                        value="blah",
                    },
                },
                remainder = {value=""},
            },
            argparse.parse_arguments("--foo='text' --bar=\"some thing\" --fizz --buzz='blah'")
        )
    end)
end)

describe("single-dash flags", function()
    it("single", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="f",
                        range="1,2",
                    },
                },
                remainder = {value=""},
            },
            argparse.parse_arguments("-f")
        )
    end)

    it("multiple, combined", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="f",
                        range="1,4",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="b",
                        range="2,4",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="z",
                        range="3,4",
                    },
                },
                remainder = {value=""},
            },
            argparse.parse_arguments("-fbz")
        )
    end)

    it("multiple, separate", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="f",
                        range="1,2",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="b",
                        range="4,5",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="z",
                        range="7,8",
                    },
                },
                remainder = {value=""},
            },
            argparse.parse_arguments("-f -b -z")
        )
    end)
end)

describe("remainder - positions", function()
    it("keeps track of single position text", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.position,
                        range="1,3",
                        value="foo",
                    },
                },
                remainder = {value=" "},
            },
            argparse.parse_arguments("foo ")
        )
    end)

    it("keeps track of multiple position text", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.position,
                        range="1,3",
                        value="foo",
                    },
                    {
                        argument_type=argparse.ArgumentType.position,
                        range="5,7",
                        value="bar",
                    },
                },
                remainder = {value="  "},
            },
            argparse.parse_arguments("foo bar  ")
        )
    end)
end)

describe("remainder - flags", function()
    it("keeps track of flag text - 001", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="f",
                        range="1,2",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="b",
                        range="4,5",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="z",
                        range="7,8",
                    },
                },
                remainder = {value=" -"},
            },
            argparse.parse_arguments("-f -b -z -")
        )
    end)

    it("keeps track of flag text - 002", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="f",
                        range="1,2",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="b",
                        range="4,5",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="z",
                        range="7,8",
                    },
                },
                remainder = {value=" --"},
            },
            argparse.parse_arguments("-f -b -z --")
        )
    end)

    it("keeps track of flag text - 003", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="f",
                        range="1,2",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="b",
                        range="4,5",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="z",
                        range="7,8",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="r",
                        range="10,12",
                    },
                },
                remainder = {value=""},
            },
            argparse.parse_arguments("-f -b -z --r")
        )
    end)

    it("sees spaces when no arguments are given", function()
        assert.same(
            { arguments = {}, remainder = {value="    "} },
            argparse.parse_arguments("    ")
        )
    end)

    it("stores the last space(s) - multiple", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="f",
                        range="1,2",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="b",
                        range="4,5",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="z",
                        range="7,8",
                    },
                },
                remainder = {value="  "},
            },
            argparse.parse_arguments("-f -b -z  ")
        )
    end)

    it("stores the last space(s) - single", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="f",
                        range="1,2",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="b",
                        range="4,5",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="z",
                        range="7,8",
                    },
                },
                remainder = {value=" "},
            },
            argparse.parse_arguments("-f -b -z ")
        )
    end)

    it("stores the last space(s) - combined", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="f",
                        range="1,2",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="b",
                        range="4,5",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="x",
                        range="7,10",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="y",
                        range="8,10",
                    },
                    {
                        argument_type=argparse.ArgumentType.flag,
                        name="z",
                        range="9,10",
                    },
                },
                remainder = {value=" "},
            },
            argparse.parse_arguments("-f -b -xyz ")
        )
    end)
end)
