-- TODO: Docstring

local argparse2 = require("plugin_template._cli.argparse2")


describe("bad input", function()
    it("knows if the user gives #bad input", function()
        local parser = argparse2.ArgumentParser.new({description="Test"})
        parser:add_argument({names="foo"})

        assert.is_false(parser.is_valid(""))
    end)
end)

describe("default", function()
    it("works with a #default", function()
        local parser = argparse2.ArgumentParser.new({description="Test"})

        assert.equal("usage: TODO", parser.get_concise_help())
    end)

    it("works with a #empty type", function()
        local parser = argparse2.ArgumentParser.new({description="Test"})
        parser:add_argument({names="foo"})

        local namespace = parser:parse_arguments("12")
        assert.same({foo="12"}, namespace)
    end)

    it("shows the full #help if the user asks for it", function()
        local parser = argparse2.ArgumentParser.new({description="Test"})

        assert.equal("usage: TODO\n\noptions:\nTODO", parser.get_full_help())
    end)
end)


describe("help", function()
    describe("full", function()
        it("shows all of the options for a #basic parser", function()
            local parser = _make_simple_parser()

            assert.equal("asdfasfsd", parser:get_full_help(""))
        end)

        it("shows all of the options for a subparser - 001", function()
            local parser = _make_simple_parser()

            assert.equal("tttt", parser:get_full_help("say "))
        end)

        it("shows all of the options for a subparser - 002", function()
            local parser = _make_simple_parser()

            assert.equal("ffffff", parser:get_full_help("say phrase "))
        end)
    end)
end)


describe("scenarios", function()
    it("works with a #basic flag argument", function()
        local parser = argparse2.ArgumentParser.new({description="Test"})
        parser:add_argument({
            names={"--force", "-f"},
            action="store_true",
            destination="force",
            help="If included, always run the action",
        })

        local namespace = parser:parse_arguments("-f")
        assert.same({force=true}, namespace)

        -- TODO: Add this later
        -- namespace = parser:parse_arguments("--force")
        -- assert.same({force=true}, namespace)
    end)

    it("works with a #basic named argument", function()
        local parser = argparse2.ArgumentParser.new({description="Test"})
        parser:add_argument({
            names={"--book"},
            help="Write your book title here",
        })

        local namespace = parser:parse_arguments('--book="Goodnight Moon"')
        assert.same({book="Goodnight Moon"}, namespace)
    end)

    it("works with a #basic position argument", function()
        local parser = argparse2.ArgumentParser.new({description="Test"})
        parser:add_argument({
            names={"book"},
            help="Write your book title here",
        })

        local namespace = parser:parse_arguments('"Goodnight Moon"')
        assert.same({book="Goodnight Moon"}, namespace)
    end)

    it("works with nested subcommands", function()
        local parser = argparse2.ArgumentParser.new({description="Test"})

        local subparsers = parser:add_subparsers({description="The available commands", destination="commands"})
        local creator = subparsers:add_parser({name="create", description="Create stuff"})

        local creator_subparsers = creator:add_subparsers({description="Some options for creating", destination="creator"})
        local create_book = creator_subparsers:add_parser({name="book", description="Create a book!"})

        create_book:add_argument({names="book", description="The book name"})
        create_book:add_argument({
            names={"--author"},
            help="The author of the book",
        })

        local namespace = parser:parse_arguments('create book "Goodnight Moon" --author="Margaret Wise Brown"')
        assert.same(
            {author="Margaret Wise Brown", book="Goodnight Moon"},
            namespace
        )
    end)

    it("works with subcommands", function()
        local parser = argparse2.ArgumentParser.new({description="Test"})
        local subparsers = parser:add_subparsers({description="The available commands", destination="commands"})
        local creator = subparsers:add_parser({name="create", description="Create stuff"})
        creator:add_argument({
            names={"book"},
            help="Create a book!",
        })
        creator:add_argument({
            names={"--author"},
            help="The author of the book",
        })

        local namespace = parser:parse_arguments('create "Goodnight Moon" --author="Margaret Wise Brown"')
        assert.same(
            {author="Margaret Wise Brown", book="Goodnight Moon"},
            namespace
        )
    end)
end)

describe("type", function()
    it("works with a known type function", function()
        local parser = argparse2.ArgumentParser.new({description="Test"})
        parser:add_argument({names="foo", type=function(value) return value .. "tt" end})

        local namespace = parser:parse_arguments("12")
        assert.same({foo="12tt"}, namespace)
    end)

    it("works with a known type name", function()
        local parser = argparse2.ArgumentParser.new({description="Test"})
        parser:add_argument({names="foo", type="number"})

        local namespace = parser:parse_arguments("12")
        assert.same({foo=12}, namespace)
    end)
end)
