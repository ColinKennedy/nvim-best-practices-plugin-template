--- Make sure that `argparse2` parses and auto-completes as expected.
---
---@module 'plugin_template.argparse2_spec'
---

local argparse2 = require("plugin_template._cli.argparse2")

---@return argparse2.ParameterParser # Create a tree of commands for unittests.
local function _make_simple_parser()
    local choices = function(data)
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

    local parser = argparse2.ParameterParser.new({ name = "top_test", help = "Test." })
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
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "--foo", action = "append", nargs = 1, count = "*", help = "Test." })

            assert.same({ foo = { "bar", "fizz", "buzz" } }, parser:parse_arguments("--foo=bar --foo=fizz --foo=buzz"))
        end)
    end)

    describe("action - custom function", function()
        it("external table", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })
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
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "--foo", action = "store_false", help = "Test." })

            assert.same({ foo = false }, parser:parse_arguments("--foo"))
        end)
    end)

    describe("action - store_true", function()
        it("simple", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "--foo", action = "store_true", help = "Test." })

            assert.same({ foo = true }, parser:parse_arguments("--foo"))
        end)
    end)
end)

describe("default", function()
    it("works with a #default", function()
        local parser = argparse2.ParameterParser.new({ help = "Test" })

        assert.equal("Usage: [--help]", parser:get_concise_help(""))
    end)

    it("works with a #empty type", function()
        local parser = argparse2.ParameterParser.new({ help = "Test" })
        parser:add_parameter({ name = "foo", help = "Test." })

        local namespace = parser:parse_arguments("12")
        assert.same({ foo = "12" }, namespace)
    end)

    it("shows the full #help if the user asks for it", function()
        local parser = argparse2.ParameterParser.new({ help = "Test" })

        assert.equal(
            [[Usage: [--help]

Options:
    --help -h    Show this help message and exit.
]],
            parser:get_full_help("")
        )
    end)
end)

-- TODO: Make sure that the help shows position choices or named argument choices

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
                [[Usage: word [--repeat] [--style] [--help]

Options:
    --repeat -r    The number of times to display the message.
    --style -s    The format of the message.
    --help -h    Show this help message and exit.
]],
                parser:get_full_help("say word ")
            )
        end)

        it("shows all of the options for a subparser - 001", function()
            local parser = _make_simple_parser()

            assert.equal(
                [[Usage: say {phrase, word} [--help]

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
                [[Usage: phrase [--repeat] [--style] [--help]

Options:
    --repeat -r    The number of times to display the message.
    --style -s    The format of the message.
    --help -h    Show this help message and exit.
]],
                parser:get_full_help("say phrase ")
            )
        end)

        it("works with a parser that has more than one choice for its name", function()
            local parser = argparse2.ParameterParser.new({ help = "Test." })
            local subparsers = parser:add_subparsers({ destination = "commands", help = "Test." })
            subparsers:add_parser({ name = "thing", choices = { "aaa", "bbb", "ccc" }, help = "Do a thing." })

            assert.equal(
                [[Usage: {aaa} [--help]

Commands:
    {aaa, bbb, ccc}    Do a thing.

Options:
    --help -h    Show this help message and exit.
]],
                parser:get_full_help("")
            )
        end)
    end)

    describe("value_hint", function()
        it("works with named arguments", function()
            local parser = argparse2.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "--thing", help = "Test.", value_hint = "FILE_PATH" })

            assert.equal(
                [[Usage: [--thing] [--help]

Options:
    --thing FILE_PATH    Test.
    --help -h    Show this help message and exit.
]],
                parser:get_full_help("")
            )
        end)

        it("works with position arguments", function()
            local parser = argparse2.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "thing", help = "Test.", value_hint = "FILE_PATH" })

            assert.equal(
                [[Usage: thing [--help]

Positional Arguments:
    thing FILE_PATH    Test.

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
        local parser = argparse2.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "--items", nargs = 2, help = "Test." })

        local namespace = parser:parse_arguments("--items foo bar")
        assert.same({ items = { "foo", "bar" } }, namespace)
    end)

    it("flag + nargs + append should parse into a string[][]", function()
        local parser = argparse2.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "--items", action = "append", nargs = 2, help = "Test." })

        local namespace = parser:parse_arguments("--items foo bar fizz buzz")
        assert.same({ { "foo", "bar" }, { "fizz", "buzz" } }, namespace)
    end)

    it("position + nargs + append should parse into a string[][]", function()
        local parser = argparse2.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "items", action = "append", nargs = 2, help = "Test." })

        local namespace = parser:parse_arguments("foo bar fizz buzz")
        assert.same({ { "foo", "bar" }, { "fizz", "buzz" } }, namespace)
    end)

    it("position + nargs + should parse into a string[]", function()
        local parser = argparse2.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "items", nargs = 2, help = "Test." })

        local namespace = parser:parse_arguments("foo bar")
        assert.same({ items = { "foo", "bar" } }, namespace)
    end)
end)

describe("set_defaults", function()
    it("works with a basic execute function", function()
        local parser = argparse2.ParameterParser.new({ help = "Test" })
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
        local parser = argparse2.ParameterParser.new({ help = "Test" })
        parser:set_defaults({})

        local namespace = parser:parse_arguments("")

        assert.same({}, namespace)
    end)

    it("works with nested parsers where a parent also defines a default", function()
        local parser = argparse2.ParameterParser.new({ help = "Test" })
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
    it("works with a #basic flag argument", function()
        local parser = argparse2.ParameterParser.new({ help = "Test" })
        parser:add_parameter({
            names = { "--force", "-f" },
            action = "store_true",
            destination = "force",
            help = "If included, always run the action",
        })

        local namespace = parser:parse_arguments("-f")
        assert.same({ force = true }, namespace)

        -- TODO: Add this later
        -- namespace = parser:parse_arguments("--force")
        -- assert.same({force=true}, namespace)
    end)

    it("works with a #basic named argument", function()
        local parser = argparse2.ParameterParser.new({ help = "Test" })
        parser:add_parameter({
            names = { "--book" },
            help = "Write your book title here",
        })

        local namespace = parser:parse_arguments('--book="Goodnight Moon"')
        assert.same({ book = "Goodnight Moon" }, namespace)
    end)

    it("works with a #basic position argument", function()
        local parser = argparse2.ParameterParser.new({ help = "Test" })
        parser:add_parameter({
            names = { "book" },
            help = "Write your book title here",
        })

        local namespace = parser:parse_arguments('"Goodnight Moon"')
        assert.same({ book = "Goodnight Moon" }, namespace)
    end)

    it("works with repeated flags", function()
        local parser = argparse2.ParameterParser.new({ "goodnight-moon", help = "Prepare to sleep or sleep." })
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
        local parser = argparse2.ParameterParser.new({ help = "Test" })

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
        local parser = argparse2.ParameterParser.new({ help = "Test" })
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
        local parser = argparse2.ParameterParser.new({ help = "Test" })
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
        local parser = argparse2.ParameterParser.new({ help = "Test" })
        parser:add_parameter({ name = "foo", type = "number", help = "Test." })

        local namespace = parser:parse_arguments("12")
        assert.same({ foo = 12 }, namespace)
    end)
end)

describe("+ flags", function()
    it("works with ++double flags", function()
        local parser = argparse2.ParameterParser.new({ help = "Test" })
        parser:add_parameter({ "++foo", action = "store_true", destination = "blah", help = "Test." })

        local namespace = parser:parse_arguments("++foo")
        assert.same({ blah = true }, namespace)
    end)

    it("works with ++named=foo arguments", function()
        local parser = argparse2.ParameterParser.new({ help = "Test" })
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

    -- -- TODO: Maybe support this in the future
    -- it("works with +s (single) flags", function()
    --     local parser = argparse2.ParameterParser.new({help="Test"})
    --     parser:add_parameter({"+s", destination="blah", type=function(value) return value .. "tt" end})
    --
    --     local namespace = parser:parse_arguments("+s=12")
    --     assert.same({blah="12tt"}, namespace)
    -- end)
end)
