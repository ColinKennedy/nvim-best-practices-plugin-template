local argparse = require("plugin_name._cli.argparse")

describe("default", function()
  it("works even if #empty #simple", function()
    assert.same(argparse.parse_args(""), {{}, {}})
  end)
end)

describe("positional arguments", function()
  it("#simple single argument", function()
    assert.same(argparse.parse_args("foo"), {{"foo"}, {}})
  end)

  it("#simple multiple arguments", function()
    assert.same(argparse.parse_args("foo bar"), {{"foo", "bar"}, {}})
  end)

  it("#escaped positional arguments 001", function()
    assert.same(argparse.parse_args("\\ foo"), {{" foo"}, {}})
  end)

  it("#escaped positional arguments 002", function()
    assert.same(argparse.parse_args("foo\\ "), {{"foo "}, {}})
  end)

  it("#escaped positional arguments 003", function()
    assert.same(argparse.parse_args("foo\\ bar"), {{"foo bar"}, {}})
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
    assert.same(argparse.parse_args("foo bar"), {{"foo bar"}, {}})
  end)

  it("#escaped spaces", function()
    assert.same(argparse.parse_args("\\ foo"), {{" foo"}, {}})
    assert.same(argparse.parse_args("foo\\ "), {{"foo "}, {}})
    assert.same(argparse.parse_args("foo\\ bar"), {{"foo bar"}, {}})
  end)
end)

describe("double-dash flags", function()
  it("mixed --flag", function()
    assert.same(
      argparse.parse_args("--foo-bar --fizz"), {{}, {["foo-bar"] = true, fizz=true}}
    )
  end)

  it("single --flag", function()
    assert.same(argparse.parse_args("--foo-bar"), {{}, {["foo-bar"] = true}})
    assert.same(argparse.parse_args("--foo"), {{}, {foo=true}})
  end)

  it("multiple", function()
    assert.same(argparse.parse_args("--foo --bar --fizz --buzz"), {{}, {foo=true, bar=true, fizz=true, buzz=true}})
  end)
end)
