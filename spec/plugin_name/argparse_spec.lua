local argparse = require("plugin_name._cli.argparse")

describe("default", function()
  it("works even if #empty #simple", function()
    print('DEBUGPRINT[2]: argparse_spec.lua:5: argparse.parse_args("")=' .. vim.inspect(argparse.parse_args("")))
    assert.same({{}, {}}, argparse.parse_args(""))
  end)
end)

describe("positional arguments", function()
  it("#simple single argument", function()
    assert.same({{"foo"}, {}}, argparse.parse_args("foo"))
  end)

  it("#simple multiple arguments", function()
    assert.same({{"foo", "bar"}, {}}, argparse.parse_args("foo bar"))
  end)

  it("#escaped positional arguments 001", function()
    assert.same({{"foo "}, {}}, argparse.parse_args("foo\\ "))
  end)

  it("#escaped positional arguments 002", function()
    assert.same({{"foo bar"}, {}}, argparse.parse_args("foo\\ bar"))
  end)
end)

describe("quotes", function()
  it("quoted positional arguments", function()
    -- TODO: Finish this
    -- assert.same(argparse.parse_args('foo "bar fizz buzz"'), {{"foo", "bar fizz buzz"'}, {}})
    -- assert.same(argparse.parse_args('"bar fizz buzz" foo'), {{"bar fizz buzz", "foo"}, {}})
    -- assert.same(argparse.parse_args('foo "bar fizz" buzz'), {{"foo", "bar fizz", "buzz"}, {}})
  end)

  it("#multiple arguments", function()
    assert.same({{"foo", "bar"}, {}}, argparse.parse_args("foo bar"))
  end)

  it("#escaped spaces 001", function()
    assert.same({{"foo "}, {}}, argparse.parse_args("foo\\ "))
  end)

  it("#escaped spaces 002", function()
    assert.same({{"foo bar"}, {}}, argparse.parse_args("foo\\ bar"))
  end)
end)

describe("double-dash flags", function()
  it("mixed --flag", function()
    assert.same(
      {{}, {["foo-bar"] = true, fizz=true}},
      argparse.parse_args("--foo-bar --fizz")
    )
  end)

  it("single --flag", function()
    assert.same({{}, {["foo-bar"] = true}}, argparse.parse_args("--foo-bar"))
    assert.same({{}, {foo=true}}, argparse.parse_args("--foo"))
  end)

  it("multiple", function()
    assert.same(
      {{}, {foo=true, bar=true, fizz=true, buzz=true}},
      argparse.parse_args("--foo --bar --fizz --buzz")
    )
  end)
end)

describe("double-dash equal-flags", function()
  it("mixed --flag", function()
    assert.same(
      {{}, {["foo-bar"] = true, fizz=true}},
      argparse.parse_args("--foo-bar --fizz")
    )
  end)

  it("single --flag", function()
    assert.same({{}, {["foo-bar"] = true}}, argparse.parse_args("--foo-bar"))
    assert.same({{}, {foo=true}}, argparse.parse_args("--foo"))
  end)

  it("multiple", function()
    assert.same(
      {{}, {foo="text", bar="some thing", fizz=true, buzz="blah"}},
      argparse.parse_args("--foo='text' --bar=\"some thing\" --fizz --buzz='blah'")
    )
  end)
end)
