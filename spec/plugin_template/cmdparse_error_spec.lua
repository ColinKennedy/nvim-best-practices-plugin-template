--- Make sure that `cmdparse` errors when it should.
---
---@module 'plugin_template.cmdparse_error_spec'
---

local cmdparse = require("plugin_template._cli.cmdparse")

describe("bad auto-complete input", function()
    it("errors if an incorrect flag is given", function()
        local parser = cmdparse.ParameterParser.new({ "arbitrary-thing", help = "Prepare to sleep or sleep." })

        parser:add_parameter({ "--bar", action = "store_true", help = "The -bar flag." })
        parser:add_parameter({ "--foo", action = "store_true", help = "The -foo flag." })

        assert.same({}, parser:get_completion("--does-not-exist "))
        assert.same({}, parser:get_completion("--bar --does-not-exist "))
        assert.same({}, parser:get_completion("--does-not-exist"))
        assert.same({}, parser:get_completion("--bar --does-not-exist"))
    end)

    describe("named arguments", function()
        it("errors if an unknown named argument is given", function()
            local parser = cmdparse.ParameterParser.new({ "arbitrary-thing", help = "Prepare to sleep or sleep." })

            parser:add_parameter({ "--bar", help = "The -bar flag." })
            parser:add_parameter({ "--foo", action = "store_true", help = "The -foo flag." })

            assert.same({}, parser:get_completion("--unknown=thing "))
            assert.same({}, parser:get_completion("--unknown=thing"))

            assert.same({}, parser:get_completion("--bar=thing --unknown=thing "))
            assert.same({}, parser:get_completion("--bar=thing --unknown=thing"))

            assert.same({}, parser:get_completion("--unknown=thing --bar=thing"))
            assert.same({}, parser:get_completion("--unknown=thing --bar=thing "))
        end)
    end)
end)

describe("bad definition input", function()
    describe("parsers definition issues", function()
        it("errors if you define a flag argument with choices", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })

            local success, result = pcall(function()
                parser:add_parameter({ "--foo", action = "store_true", choices = { "f" }, help = "Test." })
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" cannot use action "store_true" and choices at the same time.', result)
        end)

        it("errors if you define a nargs=0 + position argument", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })

            local success, result = pcall(function()
                parser:add_parameter({ "foo", nargs = 0, help = "Test." })
            end)

            assert.is_false(success)
            assert.equal('Parameter "foo" cannot be nargs=0.', result)
        end)

        it("errors if you define a nargs + flag argument", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })

            local success, result = pcall(function()
                parser:add_parameter({ "--foo", action = "store_true", nargs = 2, help = "Test." })
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" cannot use action "store_true" and nargs at the same time.', result)
        end)

        it("errors if you define a position parameter + action store_true #asdf", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })

            local success, result = pcall(function()
                parser:add_parameter({ "ɧelp", action = "store_true", help = "Test." })
            end)

            assert.is_false(success)
            assert.equal('Parameter "ɧelp" cannot use action="store_true".', result)
        end)

        it("errors if a custom type=foo doesn't return a value - 001", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "--foo", type = tonumber, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("--foo=not_a_number")
            end)

            assert.is_false(success)
            assert.equal(
                'Parameter "--foo" failed to find a value. Please check your `type` parameter and fix it!',
                result
            )

            success, result = pcall(function()
                return parser:parse_arguments("--foo=123")
            end)

            assert.is_true(success)
            assert.same({ foo = 123 }, result)
        end)

        it("errors if a custom type=foo doesn't return a value - 002", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
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
            assert.equal(
                'Parameter "--foo" failed to find a value. Please check your `type` parameter and fix it!',
                result
            )

            success, result = pcall(function()
                return parser:parse_arguments("--foo=123")
            end)

            assert.is_false(success)
            assert.equal(
                'Parameter "--foo" failed to find a value. Please check your `type` parameter and fix it!',
                result
            )
        end)

        it("errors if no name is give", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })

            local success, result = pcall(function()
                parser:add_parameter({
                    nargs = 1,
                    type = function(_)
                        return nil
                    end,
                    help = "Test.",
                })
            end)

            assert.is_false(success)
            assert.equal(
                [[Options "{
  help = "Test.",
  nargs = 1,
  type = <function 1>
}" is missing a "name" key.]],
                result
            )
        end)

        it("includes named argument choices", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
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
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
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
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
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
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
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
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
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

        describe("nargs", function()
            describe("nargs number", function()
                it("errors if not enough values are given", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })
                    parser:add_parameter({ "--foo", nargs = 2, help = "Test." })
                    parser:add_parameter({ "--bar", nargs = 2, help = "Test." })

                    local command = "--foo thing --bar something else"
                    local success, result = pcall(function()
                        parser:parse_arguments(command)
                    end)

                    assert.is_false(success)
                    assert.equal('Parameter "--foo" requires "2" values. Got "1" value.', result)

                    success, result = pcall(function()
                        parser:get_completion(command)
                    end)

                    assert.is_false(success)
                    assert.equal('Parameter "--foo" requires "2" values. Got "1" value.', result)
                end)

                it("works with nargs=2 + count", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    local success, result = pcall(function()
                        parser:add_parameter({ "--foo", nargs = 2, action = "count", help = "Test." })
                    end)

                    assert.is_false(success)
                    assert.equal('Parameter "--foo" cannot use action "count" and nargs at the same time.', result)
                end)

                it("works with nargs=2 + store_false", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    local success, result = pcall(function()
                        parser:add_parameter({ "--foo", nargs = 2, action = "store_false", help = "Test." })
                    end)

                    assert.is_false(success)
                    assert.equal(
                        'Parameter "--foo" cannot use action "store_false" and nargs at the same time.',
                        result
                    )
                end)

                it("works with nargs=2 + store_true", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    local success, result = pcall(function()
                        parser:add_parameter({ "--foo", nargs = 2, action = "store_true", help = "Test." })
                    end)

                    assert.is_false(success)
                    assert.equal('Parameter "--foo" cannot use action "store_true" and nargs at the same time.', result)
                end)
            end)

            describe("nargs *", function()
                it("works with nargs=* + count", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    local success, result = pcall(function()
                        parser:add_parameter({ "--foo", nargs = "*", action = "count", help = "Test." })
                    end)

                    assert.is_false(success)
                    assert.equal('Parameter "--foo" cannot use action "count" and nargs at the same time.', result)
                end)

                it("works with nargs=* + store_false", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test." })

                    local success, result = pcall(function()
                        parser:add_parameter({ "--foo", nargs = "*", action = "store_false", help = "Test." })
                    end)

                    assert.is_false(success)
                    assert.equal(
                        'Parameter "--foo" cannot use action "store_false" and nargs at the same time.',
                        result
                    )
                end)

                it("works with nargs=* + store_true", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    local success, result = pcall(function()
                        parser:add_parameter({ "--foo", nargs = "*", action = "store_true", help = "Test." })
                    end)

                    assert.is_false(success)
                    assert.equal('Parameter "--foo" cannot use action "store_true" and nargs at the same time.', result)
                end)
            end)

            describe("nargs +", function()
                it("works with nargs=+ + count", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    local success, result = pcall(function()
                        parser:add_parameter({ "--foo", nargs = "+", action = "count", help = "Test." })
                    end)

                    assert.is_false(success)
                    assert.equal('Parameter "--foo" cannot use action "count" and nargs at the same time.', result)
                end)

                it("works with nargs=+ + store_false", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    local success, result = pcall(function()
                        parser:add_parameter({ "--foo", nargs = "+", action = "store_false", help = "Test." })
                    end)

                    assert.is_false(success)
                    assert.equal(
                        'Parameter "--foo" cannot use action "store_false" and nargs at the same time.',
                        result
                    )
                end)

                it("works with nargs=+ + store_true", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    local success, result = pcall(function()
                        parser:add_parameter({ "--foo", nargs = "+", action = "store_true", help = "Test." })
                    end)

                    assert.is_false(success)
                    assert.equal('Parameter "--foo" cannot use action "store_true" and nargs at the same time.', result)
                end)
            end)

            describe("nargs + --foo=bar named argument syntax", function()
                it("errors with nargs=2 and --foo=bar syntax", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    parser:add_parameter({ "--foo", nargs = 2, help = "Test." })

                    local success, result = pcall(function()
                        parser:parse_arguments("--foo=thing")
                    end)

                    assert.is_false(success)
                    assert.equal('Parameter "--foo" requires "2" values. Got "1" value.', result)
                end)

                it("works with nargs=* and --foo=bar syntax", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    parser:add_parameter({ "--foo", nargs = "*", help = "Test." })

                    assert.same({ foo = "thing" }, parser:parse_arguments("--foo=thing"))
                end)

                it("works with nargs=+ and --foo=bar syntax", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test" })

                    parser:add_parameter({ "--foo", nargs = "+", help = "Test." })

                    assert.same({ foo = "thing" }, parser:parse_arguments("--foo=thing"))
                end)
            end)
        end)
    end)

    describe("simple", function()
        it("does not error if there is no text and all arguments are optional", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "foo", required = false, help = "Test." })

            parser:parse_arguments("")
        end)

        it("errors if a flag is given instead of an expected position", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })

            parser:add_parameter({ "foo", help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("--not=a_position")
            end)

            assert.is_false(success)
            assert.equal('Parameter "foo" must be defined.', result)
        end)

        it("errors if nargs doesn't get enough expected values", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })

            parser:add_parameter({ "--foo", nargs = 3, required = true, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("--foo thing another")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" requires "3" values. Got "2" values.', result)
        end)

        it("errors if the user is #missing a required flag argument - 001", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })

            parser:add_parameter({ "--foo", action = "store_true", required = true, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" must be defined.', result)
        end)

        it("errors if the user is #missing a required flag argument - 002", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
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
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "--foo", required = true, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" must be defined.', result)
        end)

        it("errors if the user is #missing a required named argument - 002", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "--foo", required = true, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("--foo= ")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" requires 1 value.', result)
        end)

        it("errors if the user is #missing a required position argument", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "foo", help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("")
            end)

            assert.is_false(success)
            assert.equal('Parameter "foo" must be defined.', result)
        end)

        it("ignores an optional position argument", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "foo", required = false, help = "Test." })

            parser:parse_arguments("")
        end)

        it("errors if the user is #missing one of several arguments - 003 - position argument", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ name = "foo", nargs = 2, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("thing")
            end)

            assert.is_false(success)
            assert.equal('Parameter "foo" requires "2" values. Got "1" value.', result)
        end)

        it("errors if the user is #missing one of several arguments - 004 - flag-value argument", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "--foo", nargs = 2, help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("--foo blah")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" requires "2" values. Got "1" value.', result)
        end)

        it("errors if a named argument in the middle of parse that is not given a value", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "--foo", required = true, help = "Test." })
            parser:add_parameter({ name = "--bar", help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("--foo= --bar=thing")
            end)

            assert.is_false(success)
            assert.equal('Parameter "--foo" requires 1 value.', result)
        end)

        it("errors if a position argument in the middle of parse that is not given a value", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
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
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
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

describe("bugs", function()
    describe("auto-complete", function()
        it("works with arbitrary-thing's flags", function()
            local parser = cmdparse.ParameterParser.new({ "arbitrary-thing", help = "Prepare to sleep or sleep." })

            parser:add_parameter({ "-a", action = "store_true", help = "The -a flag." })
            parser:add_parameter({ "-b", action = "store_true", help = "The -b flag." })
            parser:add_parameter({ "-c", action = "store_true", help = "The -c flag." })
            parser:add_parameter({ "-f", action = "store_true", count = "*", help = "The -f flag." })
            parser:add_parameter({
                "-v",
                action = "store_true",
                count = "*",
                destination = "verbose",
                help = "The -v flag.",
            })

            assert.same({ "-c", "-f", "-v", "--help" }, parser:get_completion("-a -b "))
        end)

        it("works with arbitrary-thing's flags - 002", function()
            local parser = cmdparse.ParameterParser.new({ "arbitrary-thing", help = "Prepare to sleep or sleep." })

            parser:add_parameter({ "--bar", action = "store_true", help = "The -bar flag." })
            parser:add_parameter({ "--foo", action = "store_true", help = "The -foo flag." })

            assert.same({}, parser:get_completion("-a -b "))
        end)
    end)
end)
