--- Make sure that `argparse2` errors when it should.
---
---@module 'plugin_template.argparse2_error'
---


local argparse2 = require("plugin_template._cli.argparse2")


describe("bad input", function()
    it("knows if the user is #missing a required flag argument #asdf", function()
        local parser = argparse2.ParameterParser.new({help="Test."})

        parser:add_parameter({"--foo", action="store_true"})

        local success, result = parser:get_completion("")

        assert.is_false(success)
        assert.equal("Tasdfasfasdf", result)
    end)

    it("knows if the user is #missing a required named argument", function()
        -- TODO: Finish
    end)

    it("knows if the user is #missing a required position argument", function()
        -- TODO: Finish
        -- local parser = argparse2.ParameterParser.new({ help = "Test" })
        -- parser:add_parameter({ name = "foo" })
        --
        -- -- TODO: Finish
        -- assert.same({ "ASDADSASDADS" }, parser:get_errors(""))
    end)

    it("knows if the user is #missing an argument - 001", function()
        -- TODO: Add argparse.NamedArgument check
    end)

    it("knows if the user is #missing an argument - 002", function()
        -- TODO: Add argparse.FlagArgument + argparse.PositionArgument check
    end)

    it("knows if the user is #missing one of several argumentis - 003", function()
        -- TODO: Add argparse.FlagArgument + argparse.PositionArgument + nargs = 2 check
    end)
end)

describe("validate arguments", function()
    it("does not error if there is no text and all arguments are optional", function()
        -- TODO: Finish
        -- local parser = {
        --     {
        --         option_type = argparse.ArgumentType.position,
        --         required = false,
        --         name = "foo",
        --     },
        -- }
        --
        -- assert.same({ success = true, messages = {} }, completion.validate_options(parser, _parse("")))
    end)

    it("errors if there is no text and at least one argument is required", function()
        -- TODO: Finish
        -- local parser = {
        --     {
        --         option_type = argparse.ArgumentType.position,
        --         required = true,
        --         name = "foo",
        --     },
        -- }
        --
        -- assert.same(
        --     { success = false, messages = { "Arguments cannot be empty." } },
        --     completion.validate_options(parser, _parse(""))
        -- )
    end)

    it("errors if a named argument is not given a value", function()
        -- TODO: Finish
        -- local parser = {
        --     {
        --         option_type = argparse.ArgumentType.named,
        --         name = "foo",
        --     },
        -- }
        --
        -- assert.same(
        --     { success = false, messages = { 'Named argument "--foo" needs a value.' } },
        --     completion.validate_options(parser, _parse("--foo="))
        -- )
    end)

    it("errors if a named argument in the middle of parse that is not given a value", function()
        -- TODO: Finish
        -- local parser = {
        --     foo = {
        --         [{
        --             option_type = argparse.ArgumentType.named,
        --             name = "bar",
        --         }] = {
        --             {
        --                 option_type = argparse.ArgumentType.named,
        --                 name = "fizz",
        --             },
        --             {
        --                 option_type = argparse.ArgumentType.named,
        --                 name = "thing",
        --             },
        --         },
        --     },
        -- }
        --
        -- assert.same(
        --     { success = false, messages = { 'Named argument "--bar" needs a value.' } },
        --     completion.validate_options(parser, _parse("foo --bar= --fizz=123"))
        -- )
    end)

    it("errors if a position argument in the middle of parse that is not given a value", function()
        -- TODO: Finish
        -- local parser = {
        --     foo = {
        --         another = { "blah" },
        --         bar = {
        --             {
        --                 option_type = argparse.ArgumentType.named,
        --                 name = "fizz",
        --             },
        --         },
        --     },
        -- }
        --
        -- assert.same(
        --     { success = false, messages = { 'Missing argument. Need one of: "another, bar".' } },
        --     completion.validate_options(parser, _parse("foo --fizz "))
        -- )
    end)

    it("errors if a position argument at the end of a parse that is not given a value", function()
        -- TODO: Finish
        -- local parser = {
        --     foo = {
        --         another = { "blah" },
        --         bar = {
        --             {
        --                 option_type = argparse.ArgumentType.named,
        --                 name = "fizz",
        --             },
        --         },
        --     },
        -- }
        --
        -- assert.same(
        --     { success = false, messages = { 'Missing argument. Need one of: "blah".' } },
        --     completion.validate_options(parser, _parse("foo another "))
        -- )
    end)
end)
