--- Make sure that `argparse2` errors when it should.
---
---@module 'plugin_template.argparse2_error'
---


local argparse2 = require("plugin_template._cli.argparse2")


-- TODO: Add a test for missing, required subparser
describe("bad input", function()
    it("errors if the user is #missing a required flag argument - 001", function()
        local parser = argparse2.ParameterParser.new({help="Test."})

        parser:add_parameter({"--foo", action="store_true", required=true})

        local success, result = pcall(function() parser:parse_arguments("") end)

        assert.is_false(success)
        assert.equal('Parameter "--foo" must be defined.', result)
    end)

    it("errors if the user is #missing a required flag argument - 002", function()
        local parser = argparse2.ParameterParser.new({help="Test."})
        parser:add_parameter({"thing", help="Test."})
        parser:add_parameter({"--foo", action="store_true", required=true, help="Test."})

        assert.same({foo=true, thing="blah"}, parser:parse_arguments("blah --foo"))

        local success, result = pcall(function() parser:parse_arguments("blah ") end)

        assert.is_false(success)
        assert.equal('Parameter "--foo" must be defined.', result)
    end)

    it("errors if the user is #missing a required named argument - 001", function()
        local parser = argparse2.ParameterParser.new({help="Test."})
        parser:add_parameter({"--foo", required=true, help="Test."})

        local success, result = pcall(function() parser:parse_arguments("") end)

        assert.is_false(success)
        assert.equal('Parameter "--foo" must be defined.', result)
    end)

    it("errors if the user is #missing a required named argument - 002", function()
        local parser = argparse2.ParameterParser.new({help="Test."})
        parser:add_parameter({"--foo", required=true, help="Test."})

        local success, result = pcall(function() parser:parse_arguments("--foo= ") end)

        assert.is_false(success)
        assert.equal('Parameter "--foo" requires 1 value.', result)
    end)

    it("errors if the user is #missing a required position argument", function()
        local parser = argparse2.ParameterParser.new({ help = "Test" })
        parser:add_parameter({ name = "foo" })

        local success, result = pcall(function() parser:parse_arguments("") end)

        assert.is_false(success)
        assert.equal('Parameter "foo" must be defined.', result)
    end)

    it("ignores an optional position argument", function()
        local parser = argparse2.ParameterParser.new({ help = "Test" })
        parser:add_parameter({ name = "foo", required = false})

        parser:parse_arguments("")
    end)

    -- TODO: Consider if we need this
    -- it("errors if the user is #missing one of several arguments - 003 - position argument", function()
    --     local parser = argparse2.ParameterParser.new({ help = "Test" })
    --     parser:add_parameter({ name = "foo", nargs=2})
    --
    --     local success, result = pcall(function() parser:parse_arguments("thing") end)
    --
    --     assert.is_false(success)
    --     assert.equal('Parameter "--foo" expects 2 values.', result)
    -- end)

    it("errors if the user is #missing one of several arguments - 004 - flag-value argument", function()
        local parser = argparse2.ParameterParser.new({ help = "Test" })
        parser:add_parameter({ name = "--foo", nargs=2})

        local success, result = pcall(function() parser:parse_arguments("--foo blah") end)

        assert.is_false(success)
        assert.equal('Parameter "--foo" expects 2 values.', result)
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
