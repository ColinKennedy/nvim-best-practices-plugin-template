--- Make sure the argument parser works as expected.
---
--- @module 'plugin_template.argparse_spec'
---

-- TODO: Consider moving this to a different branch in the repo or move the
-- whole argparse into a different Lua project
local argparse = require("plugin_template._cli.argparse")

describe("default", function()
    it("works even if #empty #simple", function()
        assert.same({ arguments = {}, text="", remainder = { value = "" } }, argparse.parse_arguments(""))
    end)
end)

describe("positional arguments", function()
    it("#simple #single argument", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.position,
                    range = {start_column=1, end_column=3},
                    value = "foo",
                },
            },
            text="foo",
            remainder = { value = "" },
        }, argparse.parse_arguments("foo"))
    end)

    it("#simple #multiple arguments", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.position,
                    range = {start_column=1, end_column=3},
                    value = "foo",
                },
                {
                    argument_type = argparse.ArgumentType.position,
                    range = {start_column=5, end_column=7},
                    value = "bar",
                },
            },
            text="foo bar",
            remainder = { value = "" },
        }, argparse.parse_arguments("foo bar"))
    end)

    it("#escaped #positional arguments 001", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.position,
                    range = {start_column=1, end_column=4},
                    value = "foo ",
                },
            },
            text="foo\\ ",
            remainder = { value = "" },
        }, argparse.parse_arguments("foo\\ "))
    end)

    it("#escaped #positional arguments 002", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.position,
                    range = {start_column=1, end_column=7},
                    value = "foo bar",
                },
            },
            text="foo\\ bar",
            remainder = { value = "" },
        }, argparse.parse_arguments("foo\\ bar"))
    end)
end)

describe("quotes", function()
    it("#quoted #position arguments", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.position,
                    range = {start_column=1, end_column=3},
                    value = "foo",
                },
                {
                    argument_type = argparse.ArgumentType.position,
                    range = {start_column=5, end_column=19},
                    value = "bar fizz buzz",
                },
            },
            text='foo "bar fizz buzz"',
            remainder = { value = "" },
        }, argparse.parse_arguments('foo "bar fizz buzz"'))
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.position,
                    range = {start_column=1, end_column=15},
                    value = "bar fizz buzz",
                },
                {
                    argument_type = argparse.ArgumentType.position,
                    range = {start_column=17, end_column=19},
                    value = "foo",
                },
            },
            text='"bar fizz buzz" foo',
            remainder = { value = "" },
        }, argparse.parse_arguments('"bar fizz buzz" foo'))
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.position,
                    range = {start_column=1, end_column=3},
                    value = "foo",
                },
                {
                    argument_type = argparse.ArgumentType.position,
                    range = {start_column=5, end_column=14},
                    value = "bar fizz",
                },
                {
                    argument_type = argparse.ArgumentType.position,
                    range = {start_column=16, end_column=19},
                    value = "buzz",
                },
            },
            text='foo "bar fizz" buzz',
            remainder = { value = "" },
        }, argparse.parse_arguments('foo "bar fizz" buzz'))
    end)

    it("flags within the quotes", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.position,
                    range = {start_column=1, end_column=3},
                    value = "foo",
                },
                {
                    argument_type = argparse.ArgumentType.position,
                    range = {start_column=5, end_column=19},
                    value = "bar -f --fizz",
                },
            },
            text="foo 'bar -f --fizz'",
            remainder = { value = "" },
        }, argparse.parse_arguments("foo 'bar -f --fizz'"))
    end)

    it("#multiple arguments", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.position,
                    range = {start_column=1, end_column=3},
                    value = "foo",
                },
                {
                    argument_type = argparse.ArgumentType.position,
                    range = {start_column=5, end_column=7},
                    value = "bar",
                },
            },
            text="foo bar",
            remainder = { value = "" },
        }, argparse.parse_arguments("foo bar"))
    end)

    it("#escaped spaces 001", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.position,
                    value = "foo ",
                    range = {start_column=1, end_column=4},
                },
            },
            text="foo\\ ",
            remainder = { value = "" },
        }, argparse.parse_arguments("foo\\ "))
    end)

    it("#escaped spaces 002", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.position,
                    value = "foo bar",
                    range = {start_column=1, end_column=7},
                },
            },
            text="foo\\ bar",
            remainder = { value = "" },
        }, argparse.parse_arguments("foo\\ bar"))
    end)

    it("#escaped #multiple backslashes - 001", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.position,
                    value = "foo\\",
                    range = {start_column=1, end_column=4},
                },
                {
                    argument_type = argparse.ArgumentType.position,
                    value = "bar",
                    range = {start_column=6, end_column=8},
                },
            },
            text="foo\\\\ bar",
            remainder = { value = "" },
        }, argparse.parse_arguments("foo\\\\ bar"))
    end)

    it("#escaped #multiple backslashes - 002", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.position,
                    value = "foo\\",
                    range = {start_column=1, end_column=4},
                },
                {
                    argument_type = argparse.ArgumentType.position,
                    value = "b\\ar",
                    range = {start_column=6, end_column=9},
                },
            },
            text="foo\\\\ b\\\\ar",
            remainder = { value = "" },
        }, argparse.parse_arguments("foo\\\\ b\\\\ar"))
    end)

    it("#escaped #multiple backslashes - 003", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.position,
                    value = "foo\\ bar",
                    range = {start_column=1, end_column=8},
                },
            },
            text="foo\\\\\\ bar",
            remainder = { value = "" },
        }, argparse.parse_arguments("foo\\\\\\ bar"))
    end)

    it("#escaped #multiple backslashes - 004", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.position,
                    value = "foo\\",
                    range = {start_column=1, end_column=4},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "z",
                    range = {start_column=6, end_column=9},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "z",
                    range = {start_column=7, end_column=9},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "z",
                    range = {start_column=8, end_column=9},
                },
            },
            text="foo\\\\ -zzz",
            remainder = { value = "" },
        }, argparse.parse_arguments("foo\\\\ -zzz"))
    end)
end)

describe("double-dash flags", function()
    it("mixed --flag", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "foo-bar",
                    range = {start_column=1, end_column=9},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "fizz",
                    range = {start_column=11, end_column=16},
                },
            },
            text="--foo-bar --fizz",
            remainder = { value = "" },
        }, argparse.parse_arguments("--foo-bar --fizz"))
    end)

    it("#single --flag", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "foo-bar",
                    range = {start_column=1, end_column=9},
                },
            },
            text="--foo-bar",
            remainder = { value = "" },
        }, argparse.parse_arguments("--foo-bar"))
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "foo",
                    range = {start_column=1, end_column=5},
                },
            },
            text="--foo",
            remainder = { value = "" },
        }, argparse.parse_arguments("--foo"))
    end)

    it("multiple", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "foo",
                    range = {start_column=1, end_column=5},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "bar",
                    range = {start_column=7, end_column=11},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "fizz",
                    range = {start_column=13, end_column=18},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "buzz",
                    range = {start_column=20, end_column=25},
                },
            },
            remainder = { value = "" },
            text="--foo --bar --fizz --buzz",
        }, argparse.parse_arguments("--foo --bar --fizz --buzz"))
    end)

    it("partial --flag= - single", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.named,
                        name="foo-bar",
                        value = false,
                        range={start_column=1, end_column=10},
                    },
                },
                text = "--foo-bar=",
                remainder = {value=""},
            },
            argparse.parse_arguments("--foo-bar=")
        )
    end)

    it("full --flag= - multiple #asdf", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.position,
                        value = "hello-world",
                        range={start_column=1, end_column=11},
                    },
                    {
                        argument_type=argparse.ArgumentType.position,
                        value = "say",
                        range={start_column=13, end_column=15},
                    },
                    {
                        argument_type=argparse.ArgumentType.position,
                        value = "word",
                        range={start_column=17, end_column=20},
                    },
                    {
                        argument_type=argparse.ArgumentType.position,
                        value = 'Hi',
                        range={start_column=22, end_column=25},
                    },
                    {
                        argument_type=argparse.ArgumentType.named,
                        name = "repeat",
                        value = "2",
                        range={start_column=27, end_column=36},
                    },
                    {
                        argument_type=argparse.ArgumentType.named,
                        name = "style",
                        value = "uppercase",
                        range={start_column=38, end_column=54},
                    },
                },
                remainder = {value=""},
                text='hello-world say word "Hi" --repeat=2 --style=uppercase',
            },
            argparse.parse_arguments('hello-world say word "Hi" --repeat=2 --style=uppercase')
        )
    end)
    it("partial --flag= - multiple", function()
        assert.same(
            {
                arguments = {
                    {
                        argument_type=argparse.ArgumentType.named,
                        name="foo-bar",
                        value = false,
                        range={start_column=1, end_column=10},
                    },
                    {
                        argument_type=argparse.ArgumentType.position,
                        range={start_column=12, end_column=15},
                        value="blah",
                    },
                    {
                        argument_type=argparse.ArgumentType.named,
                        name="fizz-buzz",
                        value = false,
                        range={start_column=17, end_column=28},
                    },
                    {
                        argument_type=argparse.ArgumentType.named,
                        name="one-more",
                        value = false,
                        range={start_column=30, end_column=40},
                    },
                },
                remainder = {value=""},
                text="--foo-bar= blah --fizz-buzz= --one-more=",
            },
            argparse.parse_arguments("--foo-bar= blah --fizz-buzz= --one-more=")
        )
    end)
end)

describe("double-dash equal-flags", function()
    it("mixed --flag", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "foo-bar",
                    range = {start_column=1, end_column=9},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "fizz",
                    range = {start_column=11, end_column=16},
                },
            },
            remainder = { value = "" },
            text="--foo-bar --fizz",
        }, argparse.parse_arguments("--foo-bar --fizz"))
    end)

    it("#single --flag", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "foo-bar",
                    range = {start_column=1, end_column=9},
                },
            },
            remainder = { value = "" },
            text="--foo-bar",
        }, argparse.parse_arguments("--foo-bar"))
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "foo",
                    range = {start_column=1, end_column=5},
                },
            },
            remainder = { value = "" },
            text="--foo",
        }, argparse.parse_arguments("--foo"))
    end)

    it("multiple", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.named,
                    name = "foo",
                    range = {start_column=1, end_column=12},
                    value = "text",
                },
                {
                    argument_type = argparse.ArgumentType.named,
                    name = "bar",
                    range = {start_column=14, end_column=31},
                    value = "some thing",
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "fizz",
                    range = {start_column=33, end_column=38},
                },
                {
                    argument_type = argparse.ArgumentType.named,
                    name = "buzz",
                    range = {start_column=40, end_column=52},
                    value = "blah",
                },
            },
            remainder = { value = "" },
            text="--foo='text' --bar=\"some thing\" --fizz --buzz='blah'",
        }, argparse.parse_arguments(
            "--foo='text' --bar=\"some thing\" --fizz --buzz='blah'"
        ))
    end)
end)

describe("single-dash flags", function()
    it("#single", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "f",
                    range = {start_column=1, end_column=2},
                },
            },
            remainder = { value = "" },
            text="-f",
        }, argparse.parse_arguments("-f"))
    end)

    it("#multiple, combined", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "f",
                    range = {start_column=1, end_column=4},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "b",
                    range = {start_column=2, end_column=4},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "z",
                    range = {start_column=3, end_column=4},
                },
            },
            text="-fbz",
            remainder = { value = "" },
        }, argparse.parse_arguments("-fbz"))
    end)

    it("#multiple, separate", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "f",
                    range = {start_column=1, end_column=2},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "b",
                    range = {start_column=4, end_column=5},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "z",
                    range = {start_column=7, end_column=8},
                },
            },
            text="-f -b -z",
            remainder = { value = "" },
        }, argparse.parse_arguments("-f -b -z"))
    end)
end)

describe("remainder - positions", function()
    it("keeps track of single position text", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.position,
                    range = {start_column=1, end_column=3},
                    value = "foo",
                },
            },
            text="foo ",
            remainder = { value = " " },
        }, argparse.parse_arguments("foo "))
    end)

    it("keeps track of multiple position text", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.position,
                    range = {start_column=1, end_column=3},
                    value = "foo",
                },
                {
                    argument_type = argparse.ArgumentType.position,
                    range = {start_column=5, end_column=7},
                    value = "bar",
                },
            },
            text="foo bar  ",
            remainder = { value = "  " },
        }, argparse.parse_arguments("foo bar  "))
    end)
end)

describe("remainder - flags", function()
    it("keeps track of flag text - 001", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "f",
                    range = {start_column=1, end_column=2},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "b",
                    range = {start_column=4, end_column=5},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "z",
                    range = {start_column=7, end_column=8},
                },
            },
            text="-f -b -z -",
            remainder = { value = " -" },
        }, argparse.parse_arguments("-f -b -z -"))
    end)

    it("keeps track of flag text - 002", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "f",
                    range = {start_column=1, end_column=2},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "b",
                    range = {start_column=4, end_column=5},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "z",
                    range = {start_column=7, end_column=8},
                },
            },
            text="-f -b -z --",
            remainder = { value = " --" },
        }, argparse.parse_arguments("-f -b -z --"))
    end)

    it("keeps track of flag text - 003", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "f",
                    range = {start_column=1, end_column=2},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "b",
                    range = {start_column=4, end_column=5},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "z",
                    range = {start_column=7, end_column=8},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "r",
                    range = {start_column=10, end_column=12},
                },
            },
            text="-f -b -z --r",
            remainder = { value = "" },
        }, argparse.parse_arguments("-f -b -z --r"))
    end)

    it("sees spaces when no arguments are given", function()
        assert.same({ arguments = {}, text = "    ", remainder = { value = "    " } }, argparse.parse_arguments("    "))
    end)

    it("stores the last space(s) - #multiple", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "f",
                    range = {start_column=1, end_column=2},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "b",
                    range = {start_column=4, end_column=5},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "z",
                    range = {start_column=7, end_column=8},
                },
            },
            text="-f -b -z  ",
            remainder = { value = "  " },
        }, argparse.parse_arguments("-f -b -z  "))
    end)

    it("stores the last space(s) - #single", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "f",
                    range = {start_column=1, end_column=2},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "b",
                    range = {start_column=4, end_column=5},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "z",
                    range = {start_column=7, end_column=8},
                },
            },
            text="-f -b -z ",
            remainder = { value = " " },
        }, argparse.parse_arguments("-f -b -z "))
    end)

    it("stores the last space(s) - combined", function()
        assert.same({
            arguments = {
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "f",
                    range = {start_column=1, end_column=2},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "b",
                    range = {start_column=4, end_column=5},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "x",
                    range = {start_column=7, end_column=10},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "y",
                    range = {start_column=8, end_column=10},
                },
                {
                    argument_type = argparse.ArgumentType.flag,
                    name = "z",
                    range = {start_column=9, end_column=10},
                },
            },
            text="-f -b -xyz ",
            remainder = { value = " " },
        }, argparse.parse_arguments("-f -b -xyz "))
    end)
end)
