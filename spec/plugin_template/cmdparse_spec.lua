--- Make sure that `cmdparse` parses and auto-completes as expected.
---
---@module 'plugin_template.cmdparse_spec'
---

local cmdparse = require("plugin_template._cli.cmdparse")
local configuration = require("plugin_template._core.configuration")
local constant = require("plugin_template._cli.cmdparse.constant")

local _DATA

--- Save the user's current configuration (so we can modify & restore it later).
local function _keep_configuration()
    _DATA = vim.deepcopy(configuration.DATA)
end

--- Revert the configuration to its previously-saved state.
local function _restore_configuration()
    configuration.DATA = _DATA
end

---@return cmdparse.ParameterParser # Create a tree of commands for unittests.
local function _make_simple_parser()
    local choices = function(data)
        if vim.tbl_contains(data.contexts, constant.ChoiceContext.help_message) then
            local output = {}

            for index = 1, 5 do
                table.insert(output, tostring(index))
            end

            return output
        end

        local value = data.text

        if value == "" then
            value = 0
        else
            value = tonumber(value)

            if type(value) ~= "number" then
                return {}
            end
        end

        --- @cast value number

        local output = {}

        for index = 1, 5 do
            table.insert(output, tostring(value + index))
        end

        return output
    end

    local function _add_repeat_parameter(parser)
        parser:add_parameter({
            names = { "--repeat", "-r" },
            choices = choices,
            help = "The number of times to display the message.",
        })
    end

    local function _add_style_parameter(parser)
        parser:add_parameter({
            names = { "--style", "-s" },
            choices = { "lowercase", "uppercase" },
            help = "The format of the message.",
        })
    end

    local parser = cmdparse.ParameterParser.new({ name = "top_test", help = "Test." })
    local subparsers = parser:add_subparsers({ destination = "commands", help = "Test." })
    local say = subparsers:add_parser({ name = "say", help = "Print stuff to the terminal." })
    local say_subparsers = say:add_subparsers({ destination = "say_commands", help = "All commands that print." })
    local say_word = say_subparsers:add_parser({ name = "word", help = "Print a single word." })
    local say_phrase = say_subparsers:add_parser({ name = "phrase", help = "Print a whole sentence." })

    _add_repeat_parameter(say_phrase)
    _add_repeat_parameter(say_word)
    _add_style_parameter(say_phrase)
    _add_style_parameter(say_word)

    return parser
end

describe("action", function()
    describe("action - append", function()
        it("simple", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "--foo", action = "append", nargs = 1, count = "*", help = "Test." })

            assert.same({ foo = { "bar", "fizz", "buzz" } }, parser:parse_arguments("--foo=bar --foo=fizz --foo=buzz"))
        end)
    end)

    describe("action - custom function", function()
        it("external table", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            local values = { "a", "bb", "ccc" }
            parser:add_parameter({
                name = "--foo",
                action = function(data)
                    local result = values[1]
                    data.namespace[result] = true

                    table.remove(values, 1)
                end,
                nargs = 1,
                count = "*",
                help = "Test.",
            })

            assert.same({ a = true, bb = true, ccc = true }, parser:parse_arguments("--foo=bar --foo=fizz --foo=buzz"))
        end)
    end)

    describe("action - store_false", function()
        it("simple", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "--foo", action = "store_false", help = "Test." })

            assert.same({ foo = false }, parser:parse_arguments("--foo"))
        end)
    end)

    describe("action - store_true", function()
        it("simple", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "--foo", action = "store_true", help = "Test." })

            assert.same({ foo = true }, parser:parse_arguments("--foo"))
        end)
    end)
end)

-- -- TODO: Add this later
-- describe("choices", function()
--     it("ensures there are no duplicate choices during a parse", function()
--         local function remove_value(array, value)
--             print("removing value from array")
--             print(value)
--             print(vim.inspect(array))
--
--             for index = #array, 1, -1 do
--                 if array[index] == value then
--                     table.remove(array, index)
--                 end
--             end
--         end
--
--         local parser = cmdparse.ParameterParser.new({ help = "Test" })
--         local values = { "1", "2", "3", "4", "5" }
--         parser:add_parameter({
--             "--items",
--             choices = function(data)
--                 print('DEBUGPRINT[5]: cmdparse_spec.lua:129: data=' .. vim.inspect(data))
--                 return values
--             end,
--             type = function(value)
--                 remove_value(values, value)
--             end,
--             count = "*",
--             help = "Test.",
--         })
--
--         assert.same({
--             "--items=1",
--             "--items=2",
--             "--items=3",
--             "--items=4",
--             "--items=5",
--         }, parser:get_completion("--items="))
--         assert.same({
--             "--items=2",
--             "--items=3",
--             "--items=4",
--             "--items=5",
--         }, parser:get_completion("--items=1 --items="))
--         assert.same({
--             "--items=2",
--             "--items=4",
--             "--items=5",
--         }, parser:get_completion("--items=1 --items=3 --items="))
--         assert.same({
--             "--items=2",
--             "--items=5",
--         }, parser:get_completion("--items=1 --items=3 --items=4 --items="))
--         assert.same({ "--items=5" }, parser:get_completion("--items=1 --items=3 --items=4 --items=2 --items="))
--     end)
-- end)

describe("configuration", function()
    before_each(_keep_configuration)
    after_each(_restore_configuration)

    describe("auto-completion", function()
        it("hides the --help flag if the user asks to, explicitly", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "--items", help = "Test." })

            assert.same({ "--items=", "--help" }, parser:get_completion(""))
            assert.same({ "--items=" }, parser:get_completion("", nil, { display = { help_flag = false } }))
        end)

        it("hides the --help flag if the user asks to, implicitly via configuration", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "--items", help = "Test." })
            configuration.DATA.cmdparse.auto_complete.display.help_flag = false

            assert.same({ "--items=" }, parser:get_completion(""))
        end)

        it("works even if the user deletess their configuration", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "--items", help = "Test." })

            configuration.DATA = {}
            assert.same({ "--items=", "--help" }, parser:get_completion(""))
        end)
    end)
end)

describe("count", function()
    it("sets a position parameter to optional when count = *", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test" })
        local parameter = parser:add_parameter({ "foo", count = "*", help = "Test." })

        assert.is_false(parameter.required)
    end)

    it("works with position + count=* parameters - 001 - multiple parameters", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "foo", nargs = "*", help = "Test." })
        parser:add_parameter({ "bar", nargs = "*", help = "Test." })
        parser:add_parameter({ "--flag", action = "store_true", help = "Test." })

        local namespace = parser:parse_arguments("1 2 3 4 --flag 5 6 7")
        assert.same({ foo = { "1", "2", "3", "4" }, flag = true, bar = { "5", "6", "7" } }, namespace)
    end)

    it("works with position + count=* parameters - 002 - split, single parameter", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "foo", action = "append", count = "*", nargs = "*", type = tonumber, help = "Test." })
        parser:add_parameter({ "--flag", action = "store_true", help = "Test." })

        local namespace = parser:parse_arguments("1 2 3 4 --flag 5 6 7")
        assert.same({ foo = { [1] = { 1, 2, 3, 4 }, [2] = { 5, 6, 7 } }, flag = true }, namespace)
    end)
end)

describe("default", function()
    it("works with a #default", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test" })

        assert.equal("Usage: [--help]", parser:get_concise_help(""))
    end)

    it("works with a #empty type", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test" })
        parser:add_parameter({ name = "foo", help = "Test." })

        local namespace = parser:parse_arguments("12")
        assert.same({ foo = "12" }, namespace)
    end)

    it("shows the full #help if the user asks for it", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test" })

        assert.equal(
            [[Usage: [--help]

Options:
    --help -h    Show this help message and exit.
]],
            parser:get_full_help("")
        )
    end)

    it("creates a default value if store_true / store_false has no value", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "--truthy", action = "store_true", help = "Test." })
        parser:add_parameter({ "--falsey", action = "store_false", help = "Test." })
        parser:add_parameter({ "--lastly", action = "store_true", default = 10, help = "Test." })

        local namespace = parser:parse_arguments("")
        assert.equal(false, namespace.truthy)
        assert.equal(true, namespace.falsey)
        assert.equal(10, namespace.lastly)

        namespace = parser:parse_arguments("--truthy --falsey --lastly")
        assert.equal(true, namespace.truthy)
        assert.equal(false, namespace.falsey)
        assert.equal(true, namespace.lastly)
    end)
end)

describe("help", function()
    describe("full", function()
        it("shows all of the options for a #basic parser - 001", function()
            local parser = _make_simple_parser()

            assert.equal(
                [[Usage: top_test {say} [--help]

Commands:
    say    Print stuff to the terminal.

Options:
    --help -h    Show this help message and exit.
]],
                parser:get_full_help("")
            )
        end)

        it("shows all of the options for a #basic parser - 002", function()
            local parser = _make_simple_parser()

            assert.equal(
                [[Usage: {word} [--repeat {1,2,3,4,5}] [--style {lowercase,uppercase}] [--help]

Options:
    --repeat -r {1,2,3,4,5}    The number of times to display the message.
    --style -s {lowercase,uppercase}    The format of the message.
    --help -h    Show this help message and exit.
]],
                parser:get_full_help("say word ")
            )
        end)

        it("shows all of the options for a subparser - 001", function()
            local parser = _make_simple_parser()

            assert.equal(
                [[Usage: {say} {phrase,word} [--help]

Commands:
    phrase    Print a whole sentence.
    word    Print a single word.

Options:
    --help -h    Show this help message and exit.
]],
                parser:get_full_help("say ")
            )
        end)

        it("shows all of the options for a subparser - 002", function()
            local parser = _make_simple_parser()

            assert.equal(
                [[Usage: {phrase} [--repeat {1,2,3,4,5}] [--style {lowercase,uppercase}] [--help]

Options:
    --repeat -r {1,2,3,4,5}    The number of times to display the message.
    --style -s {lowercase,uppercase}    The format of the message.
    --help -h    Show this help message and exit.
]],
                parser:get_full_help("say phrase ")
            )
        end)

        it("shows even if there parsing errors", function()
            local function _assert(parser, command, expected)
                local success, result = pcall(function()
                    parser:parse_arguments(command)
                end)

                assert.is_false(success)
                assert.equal(expected, result)
            end

            local parser = _make_simple_parser()

            _assert(
                parser,
                "does_not_exist --help",
                [[Usage: top_test {say} [--help]

Commands:
    say    Print stuff to the terminal.

Options:
    --help -h    Show this help message and exit.
]]
            )
            _assert(
                parser,
                "say does_not_exist --help",
                [[Usage: {say} {phrase,word} [--help]

Commands:
    phrase    Print a whole sentence.
    word    Print a single word.

Options:
    --help -h    Show this help message and exit.
]]
            )
            _assert(
                parser,
                "say phrase does_not_exist --help",
                [[Usage: {phrase} [--repeat {1,2,3,4,5}] [--style {lowercase,uppercase}] [--help]

Options:
    --repeat -r {1,2,3,4,5}    The number of times to display the message.
    --style -s {lowercase,uppercase}    The format of the message.
    --help -h    Show this help message and exit.
]]
            )
        end)

        it("works with a parser that has more than one choice for its name", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            local subparsers = parser:add_subparsers({ destination = "commands", help = "Test." })
            subparsers:add_parser({ name = "thing", choices = { "aaa", "bbb", "ccc" }, help = "Do a thing." })

            assert.equal(
                [[Usage: {aaa} [--help]

Commands:
    {aaa,bbb,ccc}    Do a thing.

Options:
    --help -h    Show this help message and exit.
]],
                parser:get_full_help("")
            )
        end)
    end)

    describe("value_hint - defaults", function()
        describe("flags", function()
            describe("choices", function()
                it("choices + default", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test." })
                    parser:add_parameter({ "--items", choices = { "a", "b" }, help = "Test." })

                    assert.equal(
                        [[Usage: [--items {a,b}] [--help]

Options:
    --items {a,b}    Test.
    --help -h    Show this help message and exit.
]],
                        parser:get_full_help("")
                    )
                end)

                it("choices + nargs=number + append", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test." })
                    parser:add_parameter({
                        "--items",
                        choices = { "a", "b" },
                        nargs = 3,
                        action = "append",
                        help = "Test.",
                    })

                    assert.equal(
                        [[Usage: [--items {a,b} {a,b} {a,b}] [--help]

Options:
    --items {a,b} {a,b} {a,b}    Test.
    --help -h    Show this help message and exit.
]],
                        parser:get_full_help("")
                    )
                end)

                it("choices + nargs=number", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test." })
                    parser:add_parameter({ "--items", choices = { "a", "b" }, nargs = 3, help = "Test." })

                    assert.equal(
                        [[Usage: [--items {a,b} {a,b} {a,b}] [--help]

Options:
    --items {a,b} {a,b} {a,b}    Test.
    --help -h    Show this help message and exit.
]],
                        parser:get_full_help("")
                    )
                end)

                it("choices + nargs=* + append", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test." })
                    parser:add_parameter({
                        "--items",
                        choices = { "a", "b" },
                        nargs = "*",
                        action = "append",
                        help = "Test.",
                    })

                    assert.equal(
                        [=[Usage: [--items [{a,b} ...]] [--help]

Options:
    --items [{a,b} ...]    Test.
    --help -h    Show this help message and exit.
]=],
                        parser:get_full_help("")
                    )
                end)

                it("choices + nargs=*", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test." })
                    parser:add_parameter({ "--items", choices = { "a", "b" }, nargs = "*", help = "Test." })

                    assert.equal(
                        [=[Usage: [--items [{a,b} ...]] [--help]

Options:
    --items [{a,b} ...]    Test.
    --help -h    Show this help message and exit.
]=],
                        parser:get_full_help("")
                    )
                end)

                it("choices + nargs=+ + append", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test." })
                    parser:add_parameter({
                        "--items",
                        choices = { "a", "b" },
                        nargs = "+",
                        action = "append",
                        help = "Test.",
                    })

                    assert.equal(
                        [=[Usage: [--items {a,b} [{a,b} ...]] [--help]

Options:
    --items {a,b} [{a,b} ...]    Test.
    --help -h    Show this help message and exit.
]=],
                        parser:get_full_help("")
                    )
                end)

                it("choices + nargs=+", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test." })
                    parser:add_parameter({ "--items", choices = { "a", "b" }, nargs = "+", help = "Test." })

                    assert.equal(
                        [=[Usage: [--items {a,b} [{a,b} ...]] [--help]

Options:
    --items {a,b} [{a,b} ...]    Test.
    --help -h    Show this help message and exit.
]=],
                        parser:get_full_help("")
                    )
                end)
            end)

            describe("no choices", function()
                it("converts - to _", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test." })
                    parser:add_parameter({ "--file-paths", help = "Test." })
                    parser:add_parameter({ "--last-thing", action = "store_true", help = "Test." })
                    parser:add_parameter({ "some-thing", help = "Test." })

                    assert.equal(
                        [=[Usage: SOME_THING [--file-paths FILE_PATHS] [--last-thing] [--help]

Positional Arguments:
    SOME_THING    Test.

Options:
    --file-paths FILE_PATHS    Test.
    --last-thing    Test.
    --help -h    Show this help message and exit.
]=],
                        parser:get_full_help("")
                    )
                end)

                it("nargs=number", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test." })
                    parser:add_parameter({ "--items", nargs = 3, help = "Test." })

                    assert.equal(
                        [=[Usage: [--items ITEMS ITEMS ITEMS] [--help]

Options:
    --items ITEMS ITEMS ITEMS    Test.
    --help -h    Show this help message and exit.
]=],
                        parser:get_full_help("")
                    )
                end)

                it("has no value hint if nargs=0", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test." })
                    parser:add_parameter({ "--thing", nargs = 0, help = "Test." })

                    assert.equal(
                        [[Usage: [--thing] [--help]

Options:
    --thing    Test.
    --help -h    Show this help message and exit.
]],
                        parser:get_full_help("")
                    )
                end)
            end)

            it("has value hint if details are empty", function()
                local parser = cmdparse.ParameterParser.new({ help = "Test." })
                parser:add_parameter({ "--thing", help = "Test." })

                assert.equal(
                    [[Usage: [--thing THING] [--help]

Options:
    --thing THING    Test.
    --help -h    Show this help message and exit.
]],
                    parser:get_full_help("")
                )
            end)
        end)

        describe("positions", function()
            describe("choices", function()
                it("choices + default", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test." })
                    parser:add_parameter({ "items", choices = { "a", "b" }, help = "Test." })

                    assert.equal(
                        [[Usage: {a,b} [--help]

Positional Arguments:
    {a,b}    Test.

Options:
    --help -h    Show this help message and exit.
]],
                        parser:get_full_help("")
                    )
                end)

                it("choices + nargs=number + append", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test." })
                    parser:add_parameter({
                        "items",
                        choices = { "a", "b" },
                        nargs = 3,
                        action = "append",
                        help = "Test.",
                    })

                    assert.equal(
                        [[
Usage: {a,b} {a,b} {a,b} [--help]

Positional Arguments:
    {a,b} {a,b} {a,b}    Test.

Options:
    --help -h    Show this help message and exit.
]],
                        parser:get_full_help("")
                    )
                end)

                it("choices + nargs=number", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test." })
                    parser:add_parameter({ "items", choices = { "a", "b" }, nargs = 3, help = "Test." })

                    assert.equal(
                        [[
Usage: {a,b} {a,b} {a,b} [--help]

Positional Arguments:
    {a,b} {a,b} {a,b}    Test.

Options:
    --help -h    Show this help message and exit.
]],
                        parser:get_full_help("")
                    )
                end)

                it("choices + nargs=* + append", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test." })
                    parser:add_parameter({
                        "items",
                        choices = { "a", "b" },
                        nargs = "*",
                        action = "append",
                        help = "Test.",
                    })

                    assert.equal(
                        [[Usage: [{a,b} ...] [--help]

Positional Arguments:
    [{a,b} ...]    Test.

Options:
    --help -h    Show this help message and exit.
]],
                        parser:get_full_help("")
                    )
                end)

                it("choices + nargs=*", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test." })
                    parser:add_parameter({ "items", choices = { "a", "b" }, nargs = "*", help = "Test." })

                    assert.equal(
                        [[Usage: [{a,b} ...] [--help]

Positional Arguments:
    [{a,b} ...]    Test.

Options:
    --help -h    Show this help message and exit.
]],
                        parser:get_full_help("")
                    )
                end)

                it("choices + nargs=+ + append", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test." })
                    parser:add_parameter({
                        "items",
                        choices = { "a", "b" },
                        nargs = "+",
                        action = "append",
                        help = "Test.",
                    })

                    assert.equal(
                        [[Usage: {a,b} [{a,b} ...] [--help]

Positional Arguments:
    {a,b} [{a,b} ...]    Test.

Options:
    --help -h    Show this help message and exit.
]],
                        parser:get_full_help("")
                    )
                end)

                it("choices + nargs=+", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test." })
                    parser:add_parameter({ "items", choices = { "a", "b" }, nargs = "+", help = "Test." })

                    assert.equal(
                        [[Usage: {a,b} [{a,b} ...] [--help]

Positional Arguments:
    {a,b} [{a,b} ...]    Test.

Options:
    --help -h    Show this help message and exit.
]],
                        parser:get_full_help("")
                    )
                end)
            end)

            describe("no choices", function()
                it("nargs=number", function()
                    local parser = cmdparse.ParameterParser.new({ help = "Test." })
                    parser:add_parameter({ "items", nargs = 3, help = "Test." })

                    assert.equal(
                        [[Usage: ITEMS ITEMS ITEMS [--help]

Positional Arguments:
    ITEMS ITEMS ITEMS    Test.

Options:
    --help -h    Show this help message and exit.
]],
                        parser:get_full_help("")
                    )
                end)
            end)

            it("has value hint if details are empty", function()
                local parser = cmdparse.ParameterParser.new({ help = "Test." })
                parser:add_parameter({ "thing", help = "Test." })

                assert.equal(
                    [[Usage: THING [--help]

Positional Arguments:
    THING    Test.

Options:
    --help -h    Show this help message and exit.
]],
                    parser:get_full_help("")
                )
            end)
        end)
    end)

    describe("value_hint", function()
        it("works with named arguments", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "--thing", help = "Test.", value_hint = "FILE_PATH" })

            assert.equal(
                [[Usage: [--thing FILE_PATH] [--help]

Options:
    --thing FILE_PATH    Test.
    --help -h    Show this help message and exit.
]],
                parser:get_full_help("")
            )
        end)

        it("works with position arguments", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "thing", help = "Test.", value_hint = "FILE_PATH" })

            assert.equal(
                [[Usage: FILE_PATH [--help]

Positional Arguments:
    FILE_PATH    Test.

Options:
    --help -h    Show this help message and exit.
]],
                parser:get_full_help("")
            )
        end)
    end)
end)

describe("nargs", function()
    it("flag + nargs + should parse into a string[]", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "--items", nargs = 2, help = "Test." })

        local namespace = parser:parse_arguments("--items foo bar")
        assert.same({ items = { "foo", "bar" } }, namespace)
    end)

    it("flag + nargs=2 + append should parse into a string[][]", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "--items", action = "append", nargs = 2, help = "Test." })

        local success, result = pcall(function()
            parser:parse_arguments("--items foo bar fizz buzz")
        end)

        assert.is_false(success)
        assert.equal('Unexpected arguments "fizz, buzz".', result)

        local namespace = parser:parse_arguments("--items foo bar")
        assert.same({ items = { { "foo", "bar" } } }, namespace)
    end)

    it("flag + nargs=* + append should parse into a string[][]", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "--items", action = "append", nargs = "*", help = "Test." })

        local namespace = parser:parse_arguments("--items foo bar fizz buzz")
        assert.same({ items = { { "foo", "bar", "fizz", "buzz" } } }, namespace)
    end)

    it("flag + nargs=+ + append should error if no argument is given", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "--items", nargs = "+", help = "Test." })

        local success, result = pcall(function()
            parser:get_completion("--items --another")
        end)

        assert.is_false(success)
        assert.equal('Parameter "--another" requires 1-or-more values. Got "0" values.', result)
    end)

    it("flag + nargs=+ + append should parse into a string[][]", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "--items", action = "append", nargs = "+", help = "Test." })

        local namespace = parser:parse_arguments("--items foo bar fizz buzz")
        assert.same({ items = { { "foo", "bar", "fizz", "buzz" } } }, namespace)
    end)

    it("flag + nargs=+ + append + count + type - #complex", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test." })
        parser:add_parameter({
            "--items",
            action = "append",
            count = "*",
            nargs = "+",
            type = tonumber,
            help = "Test.",
        })
        parser:add_parameter({ "--other", help = "Test." })

        local namespace = parser:parse_arguments("--items 12 2 3 --other buzz --items 12 1 93")
        assert.same({ items = { { 12, 2, 3 }, { 12, 1, 93 } }, other = "buzz" }, namespace)
    end)

    it("position + nargs=2 + append should parse into a string[][]", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "items", action = "append", nargs = 2, help = "Test." })

        local success, result = pcall(function()
            parser:parse_arguments("foo bar fizz buzz")
        end)

        assert.is_false(success)
        assert.equal('Unexpected arguments "fizz, buzz".', result)

        local namespace = parser:parse_arguments("foo bar")
        assert.same({ items = { { "foo", "bar" } } }, namespace)
    end)

    it("position + nargs=2 + append + count should parse into a string[][]", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "items", action = "append", count = "*", nargs = 2, help = "Test." })

        local namespace = parser:parse_arguments("foo bar fizz buzz")
        assert.same({ items = { { "foo", "bar" }, { "fizz", "buzz" } } }, namespace)
    end)

    it("position + nargs=2 + append + count + choices should parse into a string[][]", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test." })
        parser:add_parameter({
            "--items",
            action = "append",
            choices = { "1", "2", "3" },
            count = "*",
            nargs = 2,
            help = "Test.",
        })

        local namespace = parser:parse_arguments("--items 1 3")
        assert.same({ items = { { "1", "3" } } }, namespace)

        local success, result = pcall(function()
            parser:parse_arguments("--items 1 3 1")
        end)

        assert.is_false(success)
        assert.equal('Unexpected argument "1".', result)

        success, result = pcall(function()
            parser:parse_arguments("--items 1 not_allowed")
        end)

        assert.is_false(success)
        assert.equal(
            'Parameter "--items" got invalid { "not_allowed" } value. Expected one of { "1", "2", "3" }.',
            result
        )
    end)

    it("position + nargs=* + append should parse into a string[][]", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "items", action = "append", nargs = "*", count = "*", help = "Test." })
        parser:add_parameter({ "--foo", help = "Test." })

        local namespace = parser:parse_arguments("foo bar --foo thing fizz buzz")
        assert.same({ foo = "thing", items = { { "foo", "bar" }, { "fizz", "buzz" } } }, namespace)
        namespace = parser:parse_arguments("foo bar fizz buzz")
        assert.same({ items = { { "foo", "bar", "fizz", "buzz" } } }, namespace)
    end)

    it("position + nargs=+ + append should parse into a string[][]", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "items", action = "append", nargs = "+", help = "Test." })

        local namespace = parser:parse_arguments("foo bar fizz buzz")
        assert.same({ items = { { "foo", "bar", "fizz", "buzz" } } }, namespace)
    end)
end)

describe("set_defaults", function()
    it("works with a basic execute function", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test" })
        local count = 0
        parser:set_defaults({
            execute = function()
                count = count + 1
            end,
        })

        local namespace = parser:parse_arguments("")

        assert.equal(0, count)

        namespace.execute(namespace)

        assert.equal(1, count)
    end)

    it("works with an #empty value", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test" })
        parser:set_defaults({})

        local namespace = parser:parse_arguments("")

        assert.same({}, namespace)
    end)

    it("works with nested parsers where a parent also defines a default", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test" })
        parser:set_defaults({ foo = "bar" })

        local subparsers = parser:add_subparsers({ destination = "commands", help = "The available commands" })
        local creator = subparsers:add_parser({ name = "create", help = "Create stuff" })
        creator:add_parameter({
            names = { "--style", "-s" },
            default = "blah",
            help = "If included, always run the action",
        })
        creator:set_defaults({ foo = "fizz" })

        assert.same({ foo = "bar" }, parser:parse_arguments(""))
        assert.same({ foo = "fizz", style = "blah" }, parser:parse_arguments("create "))
    end)
end)

describe("scenarios", function()
    describe("subparsers", function()
        it("errors if the last argument is a required subparser and it has required parameters", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            local subparsers = parser:add_subparsers({
                destination = "commands",
                help = "All commands.",
                required = true,
            })

            local say = subparsers:add_parser({ "say", help = "Test." })
            say:add_parameter({ "inner_thing", help = "Test." })

            local success, result = pcall(function()
                parser:parse_arguments("say")
            end)

            assert.is_false(success)
            assert.equal('Parameter "inner_thing" must be defined.', result)
        end)

        it("passes if the last argument is a required subparser but its parameters are all optional", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            local subparsers = parser:add_subparsers({
                destination = "commands",
                help = "All commands.",
                required = true,
            })

            local say = subparsers:add_parser({ "say", help = "Test." })
            say:add_parameter({ "--thing", action = "store_false", help = "Test." })

            assert.same({ thing = true }, parser:parse_arguments("say"))
        end)

        it("passes if the last argument subparser is optional", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            local subparsers = parser:add_subparsers({
                destination = "commands",
                help = "All commands.",
                required = false,
            })

            local say = subparsers:add_parser({ "say", help = "Test." })
            say:add_parameter({ "inner_thing", help = "Test." })

            local namespace = parser:parse_arguments("")
            assert.same({}, namespace)
        end)
    end)

    it("works with a #basic flag argument", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test" })
        parser:add_parameter({
            names = { "--force", "-f" },
            action = "store_true",
            destination = "force",
            help = "If included, always run the action",
        })

        local namespace = parser:parse_arguments("-f")
        assert.same({ force = true }, namespace)

        namespace = parser:parse_arguments("--force")
        assert.same({ force = true }, namespace)
    end)

    it("works with a #basic named argument", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test" })
        parser:add_parameter({
            names = { "--book" },
            help = "Write your book title here",
        })

        local namespace = parser:parse_arguments('--book="Goodnight Moon"')
        assert.same({ book = "Goodnight Moon" }, namespace)
    end)

    it("works with a #basic position argument", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test" })
        parser:add_parameter({
            names = { "book" },
            help = "Write your book title here",
        })

        local namespace = parser:parse_arguments('"Goodnight Moon"')
        assert.same({ book = "Goodnight Moon" }, namespace)
    end)

    it("works with repeated flags", function()
        local parser = cmdparse.ParameterParser.new({ "goodnight-moon", help = "Prepare to sleep or sleep." })
        local subparsers = parser:add_subparsers({
            destination = "commands",
            help = "All commands for goodnight-moon.",
            required = true,
        })

        local sleep = subparsers:add_parser({ "sleep", help = "Sleep tight!" })
        sleep:add_parameter({
            "-z",
            action = "count",
            count = "*",
            help = "The number of Zzz to print.",
            nargs = 0,
        })

        sleep:set_execute(function(namespace)
            assert.same(3, namespace.z)
        end)

        local namespace = parser:parse_arguments("sleep -z -z -z")

        namespace.execute(namespace)
    end)

    it("works with nested subcommands", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test" })

        local subparsers = parser:add_subparsers({ destination = "commands", help = "The available commands" })
        local creator = subparsers:add_parser({ name = "create", help = "Create stuff" })

        local creator_subparsers =
            creator:add_subparsers({ destination = "creator", help = "Some options for creating" })
        local create_book = creator_subparsers:add_parser({ name = "book", help = "Create a book!" })

        create_book:add_parameter({ name = "book", help = "The book name" })
        create_book:add_parameter({
            names = { "--author" },
            help = "The author of the book",
        })

        local namespace = parser:parse_arguments('create book "Goodnight Moon" --author="Margaret Wise Brown"')
        assert.same({ author = "Margaret Wise Brown", book = "Goodnight Moon" }, namespace)
    end)

    it("works with subcommands", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test" })
        local subparsers = parser:add_subparsers({ destination = "commands", help = "The available commands" })
        local creator = subparsers:add_parser({ name = "create", help = "Create stuff" })
        creator:add_parameter({
            names = { "book" },
            help = "Create a book!",
        })
        creator:add_parameter({
            names = { "--author" },
            help = "The author of the book",
        })

        local namespace = parser:parse_arguments('create "Goodnight Moon" --author="Margaret Wise Brown"')
        assert.same({ author = "Margaret Wise Brown", book = "Goodnight Moon" }, namespace)
    end)
end)

describe("type", function()
    it("works with a known type function", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test" })
        parser:add_parameter({
            name = "foo",
            type = function(value)
                return value .. "tt"
            end,
            help = "Test.",
        })

        local namespace = parser:parse_arguments("12")
        assert.same({ foo = "12tt" }, namespace)
    end)

    it("works with a known type name", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test" })
        parser:add_parameter({ name = "foo", type = "number", help = "Test." })

        local namespace = parser:parse_arguments("12")
        assert.same({ foo = 12 }, namespace)
    end)
end)

describe("utf-8", function()
    describe("get_completion", function()
        it("works with flag parameters", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "--ɧelp", action = "store_true", help = "Test." })

            assert.same({ "--ɧelp" }, parser:get_completion("--ɧel"))
        end)

        it("works with position parameters - 001", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "ɧelp", help = "Test." })

            assert.same({}, parser:get_completion("ɧel"))
        end)

        it("works with position parameters - 002", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "ɧelp", choices = { "a", "bb", "ccc" }, help = "Test." })

            assert.same({ "ccc" }, parser:get_completion("cc"))
        end)

        it("works with named parameters", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "--ɧelp", choices = { "aa", "bb" }, help = "Test." })

            assert.same({ "--ɧelp=" }, parser:get_completion("--ɧ"))
            assert.same({ "--ɧelp=" }, parser:get_completion("--ɧel"))
            assert.same({ "--ɧelp=" }, parser:get_completion("--ɧelp"))
            assert.same({ "--ɧelp=aa", "--ɧelp=bb" }, parser:get_completion("--ɧelp="))
        end)
    end)

    describe("parse_arguments", function()
        it("works with flag parameters", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "--ɧelp", action = "store_true", help = "Test." })

            local namespace = parser:parse_arguments("--ɧelp")
            assert.same({ ["ɧelp"] = true }, namespace)
        end)

        it("works with position parameters", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "ɧ", help = "Test." })

            local namespace = parser:parse_arguments("thing")
            assert.same({ ["ɧ"] = "thing" }, namespace)
        end)

        it("works with named parameters", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ "--ɧelp", help = "Test." })

            local namespace = parser:parse_arguments("--ɧelp=thing")
            assert.same({ ["ɧelp"] = "thing" }, namespace)
        end)
    end)
end)

describe("+ flags", function()
    it("works with ++double flags", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test" })
        parser:add_parameter({ "++foo", action = "store_true", destination = "blah", help = "Test." })

        local namespace = parser:parse_arguments("++foo")
        assert.same({ blah = true }, namespace)
    end)

    it("works with ++named=foo arguments", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test" })
        parser:add_parameter({
            "++foo",
            destination = "blah",
            type = function(value)
                return value .. "tt"
            end,
            help = "Test.",
        })

        local namespace = parser:parse_arguments("++foo=12")
        assert.same({ blah = "12tt" }, namespace)
    end)

    it("works with +s (single) flags", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test" })
        parser:add_parameter({
            "+s",
            destination = "blah",
            type = function(value)
                return value .. "tt"
            end,
            help = "Test.",
        })

        local namespace = parser:parse_arguments("+s 12")
        assert.same({ blah = "12tt" }, namespace)
    end)
end)

describe("quotes", function()
    describe("position arguments", function()
        it("processes -1 as a #position argument instead of a flag argument", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "value", type = tonumber, help = "Test." })

            local namespace = parser:parse_arguments('"-1"')
            assert.same({ value = -1 }, namespace)

            namespace = parser:parse_arguments("'-1'")
            assert.same({ value = -1 }, namespace)
        end)
    end)
end)
