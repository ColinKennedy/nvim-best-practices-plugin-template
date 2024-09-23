--- Make sure that `argparse2` errors when it should.
---
---@module 'plugin_template.argparse2_error_spec'
---

local argparse2 = require("plugin_template._cli.argparse2")

describe("bad input", function()
    describe("choices", function()
        it("errors if you define a flag argument with choices", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })

            local success, result = pcall(function()
                parser:add_parameter({ "--foo", action = "store_true", choices = { "f" }, help = "Test." })
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" cannot use action and choices at the same time.', result)
        end)

        it("errors if you define a nargs + flag argument", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })

            local success, result = pcall(function()
                parser:add_parameter({ "--foo", action = "store_true", nargs = 2, help = "Test." })
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" cannot use action and nargs at the same time.', result)
        end)

        it("errors if a custom type=foo doesn't return a value - 001", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "--foo", type = tonumber, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("--foo=not_a_number")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" failed to find a value. Please fix your bug!', result)

            success, result = pcall(function()
                return parser:parse_arguments("--foo=123")
            end)

            assert.is_true(success)
            assert.same({ foo = 123 }, result)
        end)

        it("errors if a custom type=foo doesn't return a value - 002", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({
                "--foo",
                nargs = 1,
                type = function(_)
                    return nil
                end,
                help = "Test.",
            })

            local success, result = pcall(function()
                parser:parse_arguments("--foo=not_a_number")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" failed to find a value. Please fix your bug!', result)

            success, result = pcall(function()
                return parser:parse_arguments("--foo=123")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" failed to find a value. Please fix your bug!', result)
        end)

        it("includes named argument choices", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "--foo", choices = { "aaa", "bbb", "zzz" }, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("--foo=not_a_valid_choice")
            end)

            assert.is_false(success)
            assert.equal(
                'Parameter "--foo" got invalid "not_a_valid_choice" value. Expected one of { "aaa", "bbb", "zzz" }.',
                result
            )
        end)

        it("includes nested subparsers argument choices - 001 required", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "thing", help = "Test." })

            local subparsers = parser:add_subparsers({ "commands", help = "Test." })
            subparsers.required = true

            local inner_parser = subparsers:add_parser({ "inner_command", help = "Test." })
            local inner_subparsers = inner_parser:add_subparsers({ "commands", help = "Test." })
            inner_subparsers.required = true
            inner_subparsers:add_parser({ "child", choices = { "foo", "bar", "thing" }, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("some_text inner_command does_not_exist")
            end)

            assert.is_false(success)
            assert.equal(
                [[Got unexpected "does_not_exist" value. Did you mean one of these incomplete parameters?
foo
bar
thing]],
                result
            )
        end)

        it("includes position argument choices", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "foo", choices = { "aaa", "bbb", "zzz" }, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("not_a_valid_choice")
            end)

            assert.is_false(success)
            assert.equal(
                'Parameter "foo" got invalid "not_a_valid_choice" value. Expected one of { "aaa", "bbb", "zzz" }.',
                result
            )
        end)

        it("includes subparsers argument choices - 001 required", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "thing", help = "Test." })
            local subparsers = parser:add_subparsers({ "commands", help = "Test." })
            subparsers.required = true
            subparsers:add_parser({ "inner_command", choices = { "foo", "bar", "thing" } })

            local success, result = pcall(function()
                parser:parse_arguments("foo")
            end)

            assert.is_false(success)
            assert.equal('Parameter "thing" must be defined.', result)

            success, result = pcall(function()
                parser:parse_arguments("something not_valid")
            end)

            assert.is_false(success)
            assert.equal(
                [[Got unexpected "not_valid" value. Did you mean one of these incomplete parameters?
foo
bar
thing]],
                result
            )
        end)

        it("includes subparsers argument choices - 002 - required", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "thing", help = "Test." })
            local subparsers = parser:add_subparsers({ "commands", help = "Test." })
            subparsers.required = false
            subparsers:add_parser({ "inner_command", choices = { "foo", "bar", "thing" } })

            local success, result = pcall(function()
                parser:parse_arguments("something not_valid_subparser")
            end)

            assert.is_false(success)
            assert.equal(
                [[Got unexpected "not_valid_subparser" value. Did you mean one of these incomplete parameters?
foo
bar
thing]],
                result
            )
        end)
    end)

    describe("simple", function()
        it("does not error if there is no text and all arguments are optional", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "foo", required = false, help = "Test." })

            parser:parse_arguments("")
        end)

        it("errors if nargs doesn't get enough expected values", function()
            local parser = argparse2.ParameterParser.new({ help = "Test." })

            parser:add_parameter({ "--foo", nargs = 3, required = true, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("--foo thing another")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" requires "3" values. Got "2" values.', result)
        end)

        it("errors if the user is #missing a required flag argument - 001", function()
            local parser = argparse2.ParameterParser.new({ help = "Test." })

            parser:add_parameter({ "--foo", action = "store_true", required = true, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" must be defined.', result)
        end)

        it("errors if the user is #missing a required flag argument - 002", function()
            local parser = argparse2.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "thing", help = "Test." })
            parser:add_parameter({ "--foo", action = "store_true", required = true, help = "Test." })

            assert.same({ foo = true, thing = "blah" }, parser:parse_arguments("blah --foo"))

            local success, result = pcall(function()
                parser:parse_arguments("blah ")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" must be defined.', result)
        end)

        it("errors if the user is #missing a required named argument - 001", function()
            local parser = argparse2.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "--foo", required = true, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" must be defined.', result)
        end)

        it("errors if the user is #missing a required named argument - 002", function()
            local parser = argparse2.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "--foo", required = true, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("--foo= ")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" requires 1 value.', result)
        end)

        it("errors if the user is #missing a required position argument", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "foo", help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("")
            end)

            assert.is_false(success)
            assert.equal('Parameter "foo" must be defined.', result)
        end)

        it("ignores an optional position argument", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "foo", required = false, help = "Test." })

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
            parser:add_parameter({ name = "--foo", nargs = 2, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("--foo blah")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" requires "2" values. Got "1" values.', result)
        end)

        it("errors if a named argument in the middle of parse that is not given a value", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "--foo", required = true, help = "Test." })
            parser:add_parameter({ name = "--bar", help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("--foo= --bar=thing")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" requires 1 value.', result)
        end)

        it("errors if a position argument in the middle of parse that is not given a value", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "foo", help = "Test." })
            parser:add_parameter({ name = "bar", help = "Test." })
            parser:add_parameter({ name = "--fizz", help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("some --fizz=thing")
            end)

            assert.is_false(success)
            assert.equal('Parameter "bar" must be defined.', result)
        end)

        it("errors if a position argument at the end of a parse that is not given a value", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "foo", help = "Test." })
            parser:add_parameter({ name = "bar", help = "Test." })
            parser:add_parameter({ name = "thing", help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("some fizz")
            end)

            assert.is_false(success)
            assert.equal('Parameter "thing" must be defined.', result)
        end)
    end)
end)
