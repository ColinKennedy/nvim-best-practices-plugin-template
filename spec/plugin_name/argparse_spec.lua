local argparse = require("plugin_name._cli.argparse")

describe("default", function()
    it("works even if #empty #simple", function()
        assert.same({ {}, {} }, argparse.parse_args(""))
    end)
end)

describe("positional arguments", function()
    it("#simple single argument", function()
        assert.same({ { "foo" }, {} }, argparse.parse_args("foo"))
    end)

    it("#simple multiple arguments", function()
        assert.same({ { "foo", "bar" }, {} }, argparse.parse_args("foo bar"))
    end)

    it("#escaped positional arguments 001", function()
        assert.same({ { "foo " }, {} }, argparse.parse_args("foo\\ "))
    end)

    it("#escaped positional arguments 002", function()
        assert.same({ { "foo bar" }, {} }, argparse.parse_args("foo\\ bar"))
    end)
end)

describe("quotes", function()
    it("quoted positional arguments", function()
        assert.same({ { "foo", "bar fizz buzz" }, {} }, argparse.parse_args('foo "bar fizz buzz"'))
        assert.same({ { "bar fizz buzz", "foo" }, {} }, argparse.parse_args('"bar fizz buzz" foo'))
        assert.same({ { "foo", "bar fizz", "buzz" }, {} }, argparse.parse_args('foo "bar fizz" buzz'))
    end)

    it("flags within the quotes", function()
        assert.same({ { "foo", "bar -f --fizz" }, {} }, argparse.parse_args("foo 'bar -f --fizz'"))
    end)

    it("#multiple arguments", function()
        assert.same({ { "foo", "bar" }, {} }, argparse.parse_args("foo bar"))
    end)

    it("#escaped spaces 001", function()
        assert.same({ { "foo " }, {} }, argparse.parse_args("foo\\ "))
    end)

    it("#escaped spaces 002", function()
        assert.same({ { "foo bar" }, {} }, argparse.parse_args("foo\\ bar"))
    end)
end)

describe("double-dash flags", function()
    it("mixed --flag", function()
        assert.same({ {}, { ["foo-bar"] = true, fizz = true } }, argparse.parse_args("--foo-bar --fizz"))
    end)

    it("single --flag", function()
        assert.same({ {}, { ["foo-bar"] = true } }, argparse.parse_args("--foo-bar"))
        assert.same({ {}, { foo = true } }, argparse.parse_args("--foo"))
    end)

    it("multiple", function()
        assert.same(
            { {}, { foo = true, bar = true, fizz = true, buzz = true } },
            argparse.parse_args("--foo --bar --fizz --buzz")
        )
    end)
end)

describe("double-dash equal-flags", function()
    it("mixed --flag", function()
        assert.same({ {}, { ["foo-bar"] = true, fizz = true } }, argparse.parse_args("--foo-bar --fizz"))
    end)

    it("single --flag", function()
        assert.same({ {}, { ["foo-bar"] = true } }, argparse.parse_args("--foo-bar"))
        assert.same({ {}, { foo = true } }, argparse.parse_args("--foo"))
    end)

    it("multiple", function()
        assert.same(
            { {}, { foo = "text", bar = "some thing", fizz = true, buzz = "blah" } },
            argparse.parse_args("--foo='text' --bar=\"some thing\" --fizz --buzz='blah'")
        )
    end)
end)

describe("single-dash flags", function()
    it("single", function()
        assert.same({ {}, { f = true } }, argparse.parse_args("-f"))
    end)

    it("multiple, combined", function()
        assert.same({ {}, { fbz = true } }, argparse.parse_args("-fbz"))
    end)

    it("multiple, separate #asdf", function()
        assert.same({ {}, { f = true, b = true, z = true } }, argparse.parse_args("-f -b -z"))
    end)
end)
