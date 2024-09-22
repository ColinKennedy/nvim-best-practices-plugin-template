--- Make sure that `argparse2` errors when it should.
---
---@module 'plugin_template.argparse2_error'
---


local argparse2 = require("plugin_template._cli.argparse2")


describe("bad input", function()
    describe("choices", function()
        it("errors if you define a flag argument with choices", function()
            -- TODO: Finish
        end)

        it("errors if you define a nargs + flag argument", function()
            -- TODO: Finish
        end)

        it("errors if a custom type=foo doesn't return a value - 001", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({"--foo", type=tonumber, help="Test."})

            local success, result = pcall(function() parser:parse_arguments("--foo=not_a_number") end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" failed to find a value. Please fix your bug!', result)

            local success, result = pcall(function() return parser:parse_arguments("--foo=123") end)

            assert.is_true(success)
            assert.same({foo=123}, result)
        end)

        it("errors if a custom type=foo doesn't return a value - 002", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({"--foo", nargs=1, type=function(...) return nil end, help="Test."})

            local success, result = pcall(function() parser:parse_arguments("--foo=not_a_number") end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" failed to find a value. Please fix your bug!', result)

            local success, result = pcall(function() return parser:parse_arguments("--foo=123") end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" failed to find a value. Please fix your bug!', result)
        end)

        it("includes named argument choices", function()
            -- TODO: Finish
        end)

        it("includes position argument choices", function()
            -- TODO: Finish
        end)

        it("includes subparsers argument choices", function()
            -- TODO: Finish
        end)
    end)

    -- TODO: Add a test for missing, required subparser
    describe("simple", function()
        it("does not error if there is no text and all arguments are optional", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "foo", required=false})

            parser:parse_arguments("")
        end)

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
            assert.equal('Parameter "--foo" requires "2" values. Got "1" values.', result)
        end)

        it("errors if a named argument in the middle of parse that is not given a value", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "--foo", required=true})
            parser:add_parameter({ name = "--bar"})

            local success, result = pcall(function() parser:parse_arguments("--foo= --bar=thing") end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" requires 1 value.', result)
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
end)
