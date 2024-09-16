-- TODO: Docstring

local argparse2 = require("plugin_template._cli.argparse2")

-- NOTE: We disable `undefined-field` for llscheck. There might be a cleaner
-- way to do this and still keep the check.
--
--- @diagnostic disable: undefined-field

--- @return ArgumentParser # Create a tree of commands for unittests.
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

    local function _add_repeat_argument(parser)
        parser:add_argument({
            names = { "--repeat", "-r" },
            choices = choices,
            description = "The number of times to display the message.",
        })
    end

    local function _add_style_argument(parser)
        parser:add_argument({
            names = { "--style", "-s" },
            choices = { "lowercase", "uppercase" },
            description = "The format of the message.",
        })
    end

    local parser = argparse2.ArgumentParser.new({ name = "top_test", description = "Test" })
    local subparsers = parser:add_subparsers({ destination = "commands" })
    local say = subparsers:add_parser({ name = "say", description = "Print stuff to the terminal." })
    local say_subparsers =
        say:add_subparsers({ destination = "say_commands", description = "All commands that print." })
    local say_word = say_subparsers:add_parser({ name = "word", description = "Print a single word." })
    local say_phrase = say_subparsers:add_parser({ name = "phrase", description = "Print a whole sentence." })

    _add_repeat_argument(say_phrase)
    _add_repeat_argument(say_word)
    _add_style_argument(say_phrase)
    _add_style_argument(say_word)

    return parser
end

describe("action", function()
    describe("action - append", function()
        it("simple", function()
            local parser = argparse2.ArgumentParser.new({ description = "Test" })
            parser:add_argument({ names = "--foo", action = "append", nargs = 1, count = "*" })

            assert.same({ foo = { "bar", "fizz", "buzz" } }, parser:parse_arguments("--foo=bar --foo=fizz --foo=buzz"))
        end)
    end)

    describe("action - custom function", function()
        it("external table", function()
            local parser = argparse2.ArgumentParser.new({ description = "Test" })
            local values = { "a", "bb", "ccc" }
            parser:add_argument({
                names = "--foo",
                action = function(data)
                    local result = values[1]
                    data.namespace[result] = true

                    table.remove(values, 1)
                end,
                nargs = 1,
                count = "*",
            })

            assert.same({ a = true, bb = true, ccc = true }, parser:parse_arguments("--foo=bar --foo=fizz --foo=buzz"))
        end)
    end)

    describe("action - store_false", function()
        it("simple", function()
            local parser = argparse2.ArgumentParser.new({ description = "Test" })
            parser:add_argument({ names = "--foo", action = "store_false" })

            assert.same({ foo = false }, parser:parse_arguments("--foo"))
        end)
    end)

    describe("action - store_true", function()
        it("simple", function()
            local parser = argparse2.ArgumentParser.new({ description = "Test" })
            parser:add_argument({ names = "--foo", action = "store_true" })

            assert.same({ foo = true }, parser:parse_arguments("--foo"))
        end)
    end)
end)

describe("bad input", function()
    it("knows if the user is #missing a required flag argument", function()
        -- TODO: Finish
    end)

    it("knows if the user is #missing a required named argument", function()
        -- TODO: Finish
    end)

    it("knows if the user is #missing a required position argument", function()
        local parser = argparse2.ArgumentParser.new({ description = "Test" })
        parser:add_argument({ names = "foo" })

        assert.same({ "ASDADSASDADS" }, parser:get_errors(""))
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

describe("default", function()
    it("works with a #default", function()
        local parser = argparse2.ArgumentParser.new({ description = "Test" })

        assert.equal("Usage: [--help]\n", parser:get_concise_help(""))
    end)

    it("works with a #empty type", function()
        local parser = argparse2.ArgumentParser.new({ description = "Test" })
        parser:add_argument({ names = "foo" })

        local namespace = parser:parse_arguments("12")
        assert.same({ foo = "12" }, namespace)
    end)

    it("shows the full #help if the user asks for it", function()
        local parser = argparse2.ArgumentParser.new({ description = "Test" })

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
                [[Usage: [--help]

Positional Arguments:
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
                [[Usage: [--repeat] [--style] [--help]

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
                [[Usage: [--help]

Positional Arguments:
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
                [[Usage: [--repeat] [--style] [--help]

Options:
    --repeat -r    The number of times to display the message.
    --style -s    The format of the message.
    --help -h    Show this help message and exit.
]],
                parser:get_full_help("say phrase ")
            )
        end)

        it("works with a parser that has more than one choice for its name", function()
            local parser = argparse2.ArgumentParser.new({ description = "Test." })
            local subparsers = parser:add_subparsers({ destination = "commands" })
            subparsers:add_parser({ name = "thing", choices = { "aaa", "bbb", "ccc" }, description = "Do a thing." })

            assert.equal(
                [[Usage: [--help]

Positional Arguments:
    {aaa, bbb, ccc}    Do a thing.

Options:
    --help -h    Show this help message and exit.
]],
                parser:get_full_help("")
            )
        end)
    end)
end)

describe("set_defaults", function()
    it("works with a basic execute function", function()
        local parser = argparse2.ArgumentParser.new({ description = "Test" })
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
        local parser = argparse2.ArgumentParser.new({ description = "Test" })
        parser:set_defaults({})

        local namespace = parser:parse_arguments("")

        assert.same({}, namespace)
    end)

    it("works with nested parsers where a parent also defines a default", function()
        local parser = argparse2.ArgumentParser.new({ description = "Test" })
        parser:set_defaults({ foo = "bar" })

        local subparsers = parser:add_subparsers({ description = "The available commands", destination = "commands" })
        local creator = subparsers:add_parser({ name = "create", description = "Create stuff" })
        creator:add_argument({
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
        local parser = argparse2.ArgumentParser.new({ description = "Test" })
        parser:add_argument({
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
        local parser = argparse2.ArgumentParser.new({ description = "Test" })
        parser:add_argument({
            names = { "--book" },
            help = "Write your book title here",
        })

        local namespace = parser:parse_arguments('--book="Goodnight Moon"')
        assert.same({ book = "Goodnight Moon" }, namespace)
    end)

    it("works with a #basic position argument", function()
        local parser = argparse2.ArgumentParser.new({ description = "Test" })
        parser:add_argument({
            names = { "book" },
            help = "Write your book title here",
        })

        local namespace = parser:parse_arguments('"Goodnight Moon"')
        assert.same({ book = "Goodnight Moon" }, namespace)
    end)

    it("works with repeated flags", function()
        local parser = argparse2.ArgumentParser.new({ "goodnight-moon", description = "Prepare to sleep or sleep." })
        local subparsers =
            parser:add_subparsers({ destination = "commands", description = "All commands for goodnight-moon." })
        subparsers.required = true

        local sleep = subparsers:add_parser({ "sleep", description = "Sleep tight!" })
        sleep:add_argument({
            "-z",
            action = "count",
            count = "*",
            description = "The number of Zzz to print.",
            nargs = 0,
        })

        sleep:set_execute(function(namespace)
            assert.same(3, namespace.z)
        end)

        local namespace = parser:parse_arguments("sleep -z -z -z")

        namespace.execute(namespace)
    end)

    it("works with nested subcommands", function()
        local parser = argparse2.ArgumentParser.new({ description = "Test" })

        local subparsers = parser:add_subparsers({ description = "The available commands", destination = "commands" })
        local creator = subparsers:add_parser({ name = "create", description = "Create stuff" })

        local creator_subparsers =
            creator:add_subparsers({ description = "Some options for creating", destination = "creator" })
        local create_book = creator_subparsers:add_parser({ name = "book", description = "Create a book!" })

        create_book:add_argument({ names = "book", description = "The book name" })
        create_book:add_argument({
            names = { "--author" },
            help = "The author of the book",
        })

        local namespace = parser:parse_arguments('create book "Goodnight Moon" --author="Margaret Wise Brown"')
        assert.same({ author = "Margaret Wise Brown", book = "Goodnight Moon" }, namespace)
    end)

    it("works with subcommands", function()
        local parser = argparse2.ArgumentParser.new({ description = "Test" })
        local subparsers = parser:add_subparsers({ description = "The available commands", destination = "commands" })
        local creator = subparsers:add_parser({ name = "create", description = "Create stuff" })
        creator:add_argument({
            names = { "book" },
            help = "Create a book!",
        })
        creator:add_argument({
            names = { "--author" },
            help = "The author of the book",
        })

        local namespace = parser:parse_arguments('create "Goodnight Moon" --author="Margaret Wise Brown"')
        assert.same({ author = "Margaret Wise Brown", book = "Goodnight Moon" }, namespace)
    end)
end)

describe("type", function()
    it("works with a known type function", function()
        local parser = argparse2.ArgumentParser.new({ description = "Test" })
        parser:add_argument({
            names = "foo",
            type = function(value)
                return value .. "tt"
            end,
        })

        local namespace = parser:parse_arguments("12")
        assert.same({ foo = "12tt" }, namespace)
    end)

    it("works with a known type name", function()
        local parser = argparse2.ArgumentParser.new({ description = "Test" })
        parser:add_argument({ names = "foo", type = "number" })

        local namespace = parser:parse_arguments("12")
        assert.same({ foo = 12 }, namespace)
    end)
end)

describe("+ flags", function()
    it("works with ++double flags", function()
        local parser = argparse2.ArgumentParser.new({ description = "Test" })
        parser:add_argument({ "++foo", action = "store_true", destination = "blah" })

        local namespace = parser:parse_arguments("++foo")
        assert.same({ blah = true }, namespace)
    end)

    it("works with ++named=foo arguments", function()
        local parser = argparse2.ArgumentParser.new({ description = "Test" })
        parser:add_argument({
            "++foo",
            destination = "blah",
            type = function(value)
                return value .. "tt"
            end,
        })

        local namespace = parser:parse_arguments("++foo=12")
        assert.same({ blah = "12tt" }, namespace)
    end)

    -- -- TODO: Maybe support this in the future
    -- it("works with +s (single) flags", function()
    --     local parser = argparse2.ArgumentParser.new({description="Test"})
    --     parser:add_argument({"+s", destination="blah", type=function(value) return value .. "tt" end})
    --
    --     local namespace = parser:parse_arguments("+s=12")
    --     assert.same({blah="12tt"}, namespace)
    -- end)
end)
