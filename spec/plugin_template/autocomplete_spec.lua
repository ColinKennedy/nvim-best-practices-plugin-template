--- Make sure auto-complete works as expected.
---
---@module 'plugin_template.autocomplete_spec'
---

local argparse2 = require("plugin_template._cli.argparse2")

-- TODO: Allow ++foo arguments instead of --

---@return argparse2.ParameterParser # Create a tree of commands for unittests.
local function _make_simple_parser()
    local choices = function(data)
        --- @cast data argparse2.ChoiceData?

        local output = {}

        if not data or data.current_value == "" then
            for index = 1, 5 do
                table.insert(output, tostring(index))
            end

            return output
        end

        local value = tonumber(data.current_value)

        if not value then
            return {}
        end

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

---@return argparse2.ParameterParser # Create a tree of commands for unittests.
local function _make_style_parser()
    local parser = argparse2.ParameterParser.new({ name = "test", help = "Test" })
    local choice = { "lowercase", "uppercase" }
    parser:add_parameter({
        name = "--style",
        choices = choice,
        destination = "style_flag",
        help = "Define how to print to the terminal",
    })
    parser:add_parameter({
        name = "style",
        destination = "style_position",
        help = "Define how to print to the terminal",
    })

    return parser
end

describe("default", function()
    it("works even if #simple", function()
        local parser = _make_simple_parser()

        assert.same({ "say", "--help", "-h" }, parser:get_completion(""))
    end)
end)

describe("plugin", function()
    it("works with a telescope-like plugin CLI", function()
        ---@class TeleskopePluginData
        ---    Data that would come from other Lua plugins.
        ---@field name string
        ---    The name of the parser to register.
        ---@field help string
        ---    A description of what this plugin does. Keep it brief! < 80 characters.
        ---@field add_parameters (fun(parser: argparse2.ParameterParser): nil)?
        ---    The callback used to add extra

        ---@return TeleskopePluginData[] # All of the Teleskope-registered plugin.
        local function _get_plugin_registry()
            return {
                {
                    name = "colorscheme",
                    help = "Preview / Select other colorschemes.",
                    add_parameters = function(parser)
                        parser:add_parameter({ "name", required = false })
                    end,
                },
                {
                    name = "jumplist",
                    help = "Jump up, jump up, and get down jump! Jump! Jump! Jump!",
                    add_parameters = function(parser)
                        local subparsers = parser:add_subparsers({ "jumplist_commands", help = "Test." })
                        local cursor = subparsers:add_parser({ "cursor", help = "Jump to the last cursor." })
                        cursor:set_execute(function()
                            return 8
                        end)
                        local tab = subparsers:add_parser({ "tab", help = "Jump to the last tab." })
                        tab:set_execute(function()
                            return 10
                        end)
                    end,
                },
            }
        end

        local parser = argparse2.ParameterParser.new({ name = "top_test", help = "Test." })
        local subparsers = parser:add_subparsers({ destination = "commands", help = "Test." })
        local teleskope = subparsers:add_parser({ name = "Teleskope", help = "Something." })
        local teleskope_subparsers = teleskope:add_subparsers({ "teleskope_commands", help = "Test." })

        for _, data in ipairs(_get_plugin_registry()) do
            local inner_parser = teleskope_subparsers:add_parser({ data.name, help = data.help })

            if data.add_parameters then
                data.add_parameters(inner_parser)
            end
        end

        assert.same({ name = "light" }, parser:parse_arguments("Teleskope colorscheme light"))
        assert.same({}, parser:parse_arguments("Teleskope jumplist"))
        local cursor_namespace = parser:parse_arguments("Teleskope jumplist cursor")
        local tab_namespace = parser:parse_arguments("Teleskope jumplist tab")
        assert.equal(8, cursor_namespace.execute())
        assert.equal(10, tab_namespace.execute())

        assert.same({ "jumplist" }, parser:get_completion("Teleskope ju"))
        assert.same({ "cursor", "tab", "--help", "-h" }, parser:get_completion("Teleskope jumplist "))
    end)
end)

describe("simple", function()
    it("works with multiple position arguments", function()
        local parser = _make_simple_parser()

        assert.same({ "say" }, parser:get_completion("sa"))
        assert.same({ "say" }, parser:get_completion("say"))
        assert.same({ "phrase", "word", "--help", "-h" }, parser:get_completion("say "))
        assert.same({ "--repeat=", "-r=", "--style=", "-s=", "--help", "-h" }, parser:get_completion("say phrase "))
    end)

    it("works when two positions start with the same text", function()
        local parser = argparse2.ParameterParser.new({ name = "top_test", help = "Test." })
        local subparsers = parser:add_subparsers({ destination = "commands", help = "Test." })
        local bottle = subparsers:add_parser({ name = "bottle", help = "Something." })
        local bottle_subparsers = bottle:add_subparsers({ destination = "bottle", help = "Test." })
        local bottles = subparsers:add_parser({ name = "bottles", help = "Somethings." })
        bottles:add_parameter({ name = "bar", help = "Any text allowed here." })

        bottle_subparsers:add_parser({ name = "foo", choices = { "foo" }, help = "Print stuff to the terminal." })

        local bottlez = subparsers:add_parser({ name = "bottlez", destination = "weird_name", help = "Test." })
        local bottlez_subparsers = bottlez:add_subparsers({ destination = "bottlez", help = "Test." })
        bottlez_subparsers:add_parser({ name = "fizz", help = "Fizzy drink." })

        assert.same({ "bottle", "bottles", "bottlez" }, parser:get_completion("bottle"))
        assert.same({ "bottles" }, parser:get_completion("bottles"))
        assert.same({ "bottlez" }, parser:get_completion("bottlez"))
        assert.same({ "foo", "--help", "-h" }, parser:get_completion("bottle "))
        assert.same({ "--help", "-h" }, parser:get_completion("bottles "))
        assert.same({ "fizz", "--help", "-h" }, parser:get_completion("bottlez "))
    end)

    it("works when two positions start with the same text - 002", function()
        local parser = argparse2.ParameterParser.new({ name = "top_test", help = "Test." })
        local subparsers = parser:add_subparsers({ destination = "commands", help = "Test." })
        local bottle = subparsers:add_parser({ name = "bottle", help = "Something." })
        local bottle_subparsers = bottle:add_subparsers({ destination = "bottle", help = "Test." })
        local bottles = subparsers:add_parser({ name = "bottles", help = "Somethings." })
        bottles:add_parameter({ name = "bar", help = "Any text allowed here." })

        bottle_subparsers:add_parser({ name = "foo", choices = { "foo" }, help = "Print stuff to the terminal." })

        local bottlez = subparsers:add_parser({ name = "bottlez", destination = "weird_name", help = "Test." })
        local bottlez_subparsers = bottlez:add_subparsers({ destination = "bottlez", help = "Test." })
        bottlez_subparsers:add_parser({ name = "fizz", help = "Fizzy drink." })

        parser:add_parameter({ name = "bottle", help = "Something." })

        -- IMPORTANT: This is a rare case where a required parameter is in
        -- `top_test` but a subparser has the same name. We prefer the current
        -- parser in this case which means preferring the required parameter.
        -- So instead of auto-completing like `"bottle"` is a partial name of
        -- some subparsers, we treat it as a parameter.
        --
        assert.same({}, parser:get_completion("bottle"))
    end)

    it("works when two positions start with the same text - 003", function()
        local parser = argparse2.ParameterParser.new({ name = "top_test", help = "Test." })
        local subparsers = parser:add_subparsers({ destination = "commands", help = "Test." })
        local bottle = subparsers:add_parser({ name = "bottle", help = "Something." })
        local bottle_subparsers = bottle:add_subparsers({ destination = "bottle", help = "Test." })
        local bottles = subparsers:add_parser({ name = "bottles", help = "Somethings." })
        bottles:add_parameter({ name = "bar", help = "Any text allowed here." })

        bottle_subparsers:add_parser({ name = "foo", choices = { "foo" }, help = "Print stuff to the terminal." })

        local bottlez = subparsers:add_parser({ name = "bottlez", destination = "weird_name", help = "Test." })
        local bottlez_subparsers = bottlez:add_subparsers({ destination = "bottlez", help = "Test." })
        bottlez_subparsers:add_parser({ name = "fizz", help = "Fizzy drink." })

        parser:add_parameter({ name = "bottle", choices = { "bots", "botz" }, help = "Something." })

        -- IMPORTANT: This is a rare case where a required parameter is in
        -- `top_test` but a subparser has the same name. We prefer the current
        -- parser in this case which means preferring the required parameter.
        -- So instead of auto-completing like `"bottle"` is a partial name of
        -- some subparsers, we treat it as a parameter.
        --
        assert.same({ "bots", "botz" }, parser:get_completion("bot"))
    end)

    it("works with a basic multi-key example", function()
        local parser = _make_simple_parser()

        assert.same({
            "--repeat=",
            "-r=",
            "--style=",
            "-s=",
            "--help",
            "-h",
        }, parser:get_completion("say phrase "))
    end)

    it("works even if there is a named / position argument at the same time - 001", function()
        local parser = _make_style_parser()

        assert.same({ "--style=", "--help", "-h" }, parser:get_completion(""))
        assert.same({}, parser:get_completion("foo"))
    end)

    it("works even if there is a named / position argument at the same time - 002", function()
        local parser = _make_style_parser()

        assert.same({}, parser:get_completion("sty"))
        -- TODO: Fix this test later. The original argparser needs to include
        -- `--`s, which it currently doesn't which is why this test is failing
        --
        -- assert.same({ "--style=" }, parser:get_completion("--sty"))
    end)

    it("works even if there is a named / position argument at the same time - 003", function()
        local parser = argparse2.ParameterParser.new({ name = "test", help = "Test" })
        local choice = { "lowercase", "uppercase" }
        parser:add_parameter({
            name = "--style",
            choices = choice,
            destination = "style_flag",
            help = "Define how to print to the terminal",
        })
        parser:add_parameter({
            name = "style",
            choices = { "style" },
            destination = "style_position",
            help = "Define how to print to the terminal",
        })

        assert.same({ "style" }, parser:get_completion("sty"))
        -- TODO: Fix this test later. The original argparser needs to include
        -- `--`s, which it currently doesn't which is why this test is failing
        --
        -- assert.same({ "--style=" }, parser:get_completion("--sty"))
    end)

    it("works with a basic multi-position example", function()
        local parser = _make_simple_parser()

        -- NOTE: Simple examples
        assert.same({ "say" }, parser:get_completion("sa"))
        assert.same({ "say" }, parser:get_completion("say"))
        assert.same({ "phrase", "word", "--help", "-h" }, parser:get_completion("say "))
        assert.same({ "phrase" }, parser:get_completion("say p"))
        assert.same({ "phrase" }, parser:get_completion("say phrase"))
        assert.same({ "--repeat=", "-r=", "--style=", "-s=", "--help", "-h" }, parser:get_completion("say phrase "))

        -- NOTE: Beginning a --double-dash named argument, maybe (we don't know yet)
        assert.same({ "--repeat=", "--style=", "--help" }, parser:get_completion("say phrase --"))
    end)
end)

describe("named argument", function()
    it("allow named argument as key", function()
        local parser = _make_style_parser()

        assert.same({ "--style=" }, parser:get_completion("--s"))
        assert.same({ "--help", "-h" }, parser:get_completion("--style=10 "))
        assert.same({}, parser:get_completion("sty"))
    end)

    -- TODO: Fix at some point
    -- it("auto-completes on the dashes - 001", function()
    --     local parser = {
    --         {
    --             option_type = completion.OptionType.named,
    --             name = "style",
    --             choices = { "lowercase", "uppercase" },
    --         },
    --     }
    --
    --     assert.same({ "--style=" }, parser:get_completion("-"), 1))
    -- end)
    --
    -- it("auto-completes on the dashes - 002", function()
    --     local parser = {
    --         {
    --             option_type = completion.OptionType.named,
    --             name = "style",
    --             choices = { "lowercase", "uppercase" },
    --         },
    --     }
    --
    --     assert.same({ "--style=" }, parser:get_completion("--"), 1))
    --     assert.same({ "--style=" }, parser:get_completion("--"), 2))
    -- end)

    it("auto-completes on a #partial argument name - 001", function()
        local parser = _make_style_parser()

        -- TODO: Not sure about these results. Check.
        assert.same({}, parser:get_completion("--s", 1))
        assert.same({}, parser:get_completion("--s", 2))
    end)

    it("auto-completes on a #partial argument name - 002", function()
        local parser = _make_style_parser()

        -- TODO: Not sure about these results. Check.
        assert.same({}, parser:get_completion("--styl", 1))
        assert.same({}, parser:get_completion("--styl", 2))
        assert.same({}, parser:get_completion("--styl", 3))
        assert.same({}, parser:get_completion("--styl", 4))
        assert.same({}, parser:get_completion("--styl", 5))
    end)

    it("auto-completes on a #partial argument name - 003", function()
        local parser = _make_style_parser()

        -- TODO: Not sure about these results. Check.
        assert.same({}, parser:get_completion("--style", 1))
        assert.same({}, parser:get_completion("--style", 2))
        assert.same({}, parser:get_completion("--style", 3))
        assert.same({}, parser:get_completion("--style", 4))
        assert.same({}, parser:get_completion("--style", 5))
        assert.same({}, parser:get_completion("--style", 6))
    end)

    it("auto-completes on a #partial argument value - 001", function()
        local parser = _make_style_parser()

        -- TODO: Not sure if these are right. Double-check
        assert.same({ "--style=lowercase" }, parser:get_completion("--style=low"))
        assert.same({}, parser:get_completion("--style=lowercase", 1))
        assert.same({}, parser:get_completion("--style=lowercase", 3))
        assert.same({}, parser:get_completion("--style=lowercase", 7))
        assert.same({}, parser:get_completion("--style=lowercase", 8))
        assert.same({}, parser:get_completion("--style=lowercase", 9))
        assert.same({}, parser:get_completion("--style=lowercase", 10))
        assert.same({}, parser:get_completion("--style=lowercase", 16))
    end)

    it("does not auto-complete if the name does not match", function()
        local parser = argparse2.ParameterParser.new({ help = "Test." })

        local choices = function(data)
            local output = {}
            local value = data.value or 0

            for index = 1, 5 do
                table.insert(output, tostring(value + index))
            end

            return output
        end

        parser:add_parameter({ "--repeat", choices = choices, help = "Number of values." })

        assert.same({}, parser:get_completion("--style=", 1))
        assert.same({}, parser:get_completion("--style=", 2))
        assert.same({}, parser:get_completion("--style=", 3))
        assert.same({}, parser:get_completion("--style=", 4))
        assert.same({}, parser:get_completion("--style=", 5))
        assert.same({}, parser:get_completion("--style=", 6))
        assert.same({}, parser:get_completion("--style=", 7))
        assert.same({}, parser:get_completion("--style=", 8))
    end)

    it("does not auto-complete the name anymore and auto-completes the value", function()
        local parser = argparse2.ParameterParser.new({ help = "Test." })

        parser:add_parameter({
            names = { "--style", "-s" },
            choices = { "lowercase", "uppercase" },
            help = "The format of the message.",
        })

        assert.same({}, parser:get_completion("--style=", 1))
        assert.same({}, parser:get_completion("--style=", 2))
        assert.same({}, parser:get_completion("--style=", 3))
        assert.same({}, parser:get_completion("--style=", 4))
        assert.same({}, parser:get_completion("--style=", 5))
        assert.same({}, parser:get_completion("--style=", 6))
        assert.same({}, parser:get_completion("--style=", 7))
    end)

    it("should only auto-complete --repeat once", function()
        local parser = _make_simple_parser()

        assert.same(
            {
                "--repeat=1",
                "--repeat=2",
                "--repeat=3",
                "--repeat=4",
                "--repeat=5",
            },
            parser:get_completion("say word --repeat= --repe", 18)
        )
        assert.same({}, parser:get_completion("say word --repeat= --repe"))
    end)

    it("suggests new named argument values based on the current value", function()
        local function _add_repeat_parameter(parser)
            parser:add_parameter({
                names = { "--repeat", "-r" },
                choices = function(data)
                    --- @cast data argparse2.ChoiceData?

                    local output = {}

                    if not data then
                        for index = 1, 5 do
                            table.insert(output, tostring(index))
                        end

                        return output
                    end

                    local value = tonumber(data.current_value)

                    if not value then
                        return {}
                    end

                    for index = 1, 5 do
                        table.insert(output, tostring(value + index))
                    end

                    return output
                end,
                default = 1,
                help = "Print to the user X number of times (default=1).",
            })
        end

        local parser = argparse2.ParameterParser.new({ help = "Test" })

        _add_repeat_parameter(parser)

        assert.same({
            "--repeat=4",
            "--repeat=5",
            "--repeat=6",
            "--repeat=7",
            "--repeat=8",
        }, parser:get_completion("--repeat=3"))
    end)
end)

describe("flag argument", function()
    -- TODO: Implement this later
    -- it("auto-completes on the dash", function()
    --     local parser = {
    --         {
    --             option_type = completion.OptionType.flag,
    --             name = "f",
    --         },
    --     }
    --
    --     assert.same({ "-f" }, parser:get_completion("-"), 1))
    -- end)

    it("does not auto-complete if at the end of the flag", function()
        local parser = argparse2.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "-f", help = "Force it." })

        assert.same({}, parser:get_completion("-f", 1))
        assert.same({}, parser:get_completion("-f", 2))
    end)
end)

describe("numbered count - named argument", function()
    it("works with count = 2", function()
        local parser = argparse2.ParameterParser.new({ help = "Test" })
        parser:add_parameter({ name = "--foo", choices = { "bar", "fizz", "buzz" }, count = 2 })

        assert.same({ "--foo=" }, parser:get_completion("--fo"))
        assert.same({ "--foo=bar", "--foo=fizz", "--foo=buzz" }, parser:get_completion("--foo="))
        assert.same({ "--foo=", "--help", "-h" }, parser:get_completion("--foo=bar "))
        assert.same({ "--foo=bar", "--foo=fizz", "--foo=buzz" }, parser:get_completion("--foo=bar --foo="))
        assert.same({ "--help", "-h" }, parser:get_completion("--foo=bar --foo=bar "))
    end)
end)

describe("numbered count - named argument", function()
    it("works with count = 2", function()
        local parser = argparse2.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ name = "--foo", choices = { "bar", "fizz", "buzz" }, count = 2 })

        assert.same({ "--foo=" }, parser:get_completion("--fo"))
        assert.same({ "--foo=bar", "--foo=fizz", "--foo=buzz" }, parser:get_completion("--foo="))
        assert.same({ "--foo=", "--help", "-h" }, parser:get_completion("--foo=bar "))
        assert.same({ "--foo=bar", "--foo=fizz", "--foo=buzz" }, parser:get_completion("--foo=bar --foo="))
        assert.same({ "--help", "-h" }, parser:get_completion("--foo=bar --foo=bar "))
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

describe("* count", function()
    describe("simple", function()
        it("works with position arguments", function()
            local parser = argparse2.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "thing", choices = { "foo" }, count = "*" })

            assert.same({ "foo", "--help", "-h" }, parser:get_completion(""))
            assert.same({ "foo" }, parser:get_completion("fo"))
            assert.same({ "foo" }, parser:get_completion("foo"))
            assert.same({ "foo", "--help", "-h" }, parser:get_completion("foo "))
            assert.same({ "foo" }, parser:get_completion("foo fo"))
            assert.same({ "foo" }, parser:get_completion("foo foo"))
            assert.same({ "foo", "--help", "-h" }, parser:get_completion("foo foo "))
            assert.same({ "foo" }, parser:get_completion("foo foo foo"))
            assert.same({ "foo", "--help", "-h" }, parser:get_completion("foo foo foo "))
        end)
    end)
end)

describe("dynamic argument", function()
    it("skips if no matches were found", function()
        -- TODO: Add
    end)

    it("works even if matches use spaces", function()
        -- TODO: The user's argument should be in quotes, basically
    end)

    it("works with positional arguments", function()
        local parser = argparse2.ParameterParser.new({ name = "top_test", help = "Test" })
        local subparsers = parser:add_subparsers({ destination = "commands", help = "All main commands." })
        local say_parser = subparsers:add_parser({ name = "say", help = "Say something." })
        say_parser:add_parameter({
            name = "thing",
            choices = function()
                return { "a", "bb", "asteroid", "tt" }
            end,
            help = "Choices that come from a function.",
        })
        local inner_subparsers = say_parser:add_subparsers({ destination = "thing_subparsers", help = "Test." })
        local thing = inner_subparsers:add_parser({ name = "thing_parser", help = "Inner thing." })
        thing:add_parameter({ name = "last_thing", choices = { "another", "last" } })

        local dynamic = inner_subparsers:add_parser({
            name = "dynamic_thing",
            choices = function()
                return { "ab", "cc", "zzz", "lazers" }
            end,
            help = "Test.",
        })
        local inner_dynamic = dynamic:add_subparsers({ name = "inner_dynamic_thing", help = "Test." })
        local different = inner_dynamic:add_parser({ name = "different", help = "Test." })
        different:add_parameter({
            name = "last",
            choices = function()
                return { "branch", "here" }
            end,
        })

        -- TODO: Improve the (default) sorting here
        -- NOTE: We don't complete the next subparsers because required
        -- parameter(s) from the `say` subparser have no been satisfied yet.
        --
        assert.same({ "a", "bb", "asteroid", "tt", "--help", "-h" }, parser:get_completion("say "))
        -- IMPORTANT: Notice we do not include `ab` in the completion because
        -- the `thing` argument is required and must be satisfied first before
        -- we can continue to the subparser.
        --
        assert.same({ "a", "asteroid" }, parser:get_completion("say a"))
        assert.same({ "ab", "cc", "lazers", "thing_parser", "zzz", "--help", "-h" }, parser:get_completion("say a "))
        assert.same({ "another", "last", "--help", "-h" }, parser:get_completion("say a thing_parser "))

        assert.same({ "different", "--help", "-h" }, parser:get_completion("say ab "))
        assert.same({ "branch", "here", "--help", "-h" }, parser:get_completion("say ab different "))
    end)
end)
