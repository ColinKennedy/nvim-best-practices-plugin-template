--- Make sure auto-complete works as expected.
---
---@module 'plugin_template.autocomplete_spec'
---

local cmdparse = require("plugin_template._cli.cmdparse")

---@return cmdparse.ParameterParser # Create a tree of commands for unittests.

--- Add `--repeat=` to `parser`.
---
---@param parser cmdparse.ParameterParser Some tree to add a new parameter.
---@param short string? The parameter name. e.g. `"-r"`.
---@param long string? The parameter name. e.g. `"--repeat"`.
---
local function _add_repeat_parameter(parser, short, long)
    local choices = function(data)
        --- @cast data cmdparse.ChoiceData?

        local output = {}

        if not data or not data.current_value or data.current_value == "" then
            for index = 1, 5 do
                table.insert(output, tostring(index))
            end

            return output
        end

        local value = tonumber(data.current_value)

        if not value then
            return {}
        end

        table.insert(output, tostring(value))

        for index = 1, 4 do
            table.insert(output, tostring(value + index))
        end

        return output
    end

    short = short or "-r"
    long = long or "--repeat"

    parser:add_parameter({
        names = { long, short },
        choices = choices,
        help = "The number of times to display the message.",
    })
end

--- Add `--style=` to `parser`.
---
---@param parser cmdparse.ParameterParser Some tree to add a new parameter.
---@param short string? The parameter name. e.g. `"-s"`.
---@param long string? The parameter name. e.g. `"--style"`.
---
local function _add_style_parameter(parser, short, long)
    short = short or "-s"
    long = long or "--style"

    parser:add_parameter({
        names = { long, short },
        choices = { "lowercase", "uppercase" },
        help = "The format of the message.",
    })
end

--- Create multi-parameter for unittests.
---
---@param pluses boolean? If ``true``, the created parameters will use + / ++.
---@return cmdparse.ParameterParser # Create a `say {phrase,word} [--repeat --style]`.
---
local function _make_simple_parser(pluses)
    local parser = cmdparse.ParameterParser.new({ name = "top_test", help = "Test." })
    local subparsers = parser:add_subparsers({ destination = "commands", help = "Test." })
    local say = subparsers:add_parser({ name = "say", help = "Print stuff to the terminal." })
    local say_subparsers = say:add_subparsers({ destination = "say_commands", help = "All commands that print." })
    local say_word = say_subparsers:add_parser({ name = "word", help = "Print a single word." })
    local say_phrase = say_subparsers:add_parser({ name = "phrase", help = "Print a whole sentence." })

    local long_repeat
    local short_repeat
    local long_style
    local short_style

    if pluses then
        long_repeat = "++repeat"
        short_repeat = "+r"
        long_style = "++style"
        short_style = "+s"
    end

    _add_repeat_parameter(say_phrase, short_repeat, long_repeat)
    _add_repeat_parameter(say_word, short_repeat, long_repeat)
    _add_style_parameter(say_phrase, short_style, long_style)
    _add_style_parameter(say_word, short_style, long_style)

    return parser
end

--- Create a --style= parameter.
---
---@param prefix string? The text used as a start for the parameter. e.g. `"--"`.
---@return cmdparse.ParameterParser # Create a tree of commands for unittests.
---
local function _make_style_parser(prefix)
    local parser = cmdparse.ParameterParser.new({ name = "test", help = "Test" })
    prefix = prefix or "--"
    local choice = { "lowercase", "uppercase" }

    parser:add_parameter({
        name = prefix .. "style",
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

        assert.same({ "say", "--help" }, parser:get_completion(""))
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
        ---@field add_parameters (fun(parser: cmdparse.ParameterParser): nil)?
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

        local parser = cmdparse.ParameterParser.new({ name = "top_test", help = "Test." })
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
        assert.same({ "cursor", "tab", "--help" }, parser:get_completion("Teleskope jumplist "))
    end)
end)

describe("simple", function()
    it("works with multiple position arguments", function()
        local parser = _make_simple_parser()

        assert.same({ "say" }, parser:get_completion("sa"))
        assert.same({ "say" }, parser:get_completion("say"))
        assert.same({ "phrase", "word", "--help" }, parser:get_completion("say "))
        assert.same({ "--repeat=", "--style=", "--help" }, parser:get_completion("say phrase "))
    end)

    it("works when two positions start with the same text", function()
        local parser = cmdparse.ParameterParser.new({ name = "top_test", help = "Test." })
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
        assert.same({ "foo", "--help" }, parser:get_completion("bottle "))
        assert.same({ "--help" }, parser:get_completion("bottles "))
        assert.same({ "fizz", "--help" }, parser:get_completion("bottlez "))
    end)

    it("works when two positions start with the same text - 002", function()
        local parser = cmdparse.ParameterParser.new({ name = "top_test", help = "Test." })
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
        local parser = cmdparse.ParameterParser.new({ name = "top_test", help = "Test." })
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
            "--style=",
            "--help",
        }, parser:get_completion("say phrase "))
    end)

    it("works even if there is a named / position argument at the same time - 001", function()
        local parser = _make_style_parser()

        assert.same({ "--style=", "--help" }, parser:get_completion(""))
        assert.same({}, parser:get_completion("foo"))
    end)

    it("works even if there is a named / position argument at the same time - 002", function()
        local parser = _make_style_parser()

        assert.same({}, parser:get_completion("sty"))
        assert.same({ "--style=" }, parser:get_completion("--sty"))
    end)

    it("works even if there is a named / position argument at the same time - 003", function()
        local parser = cmdparse.ParameterParser.new({ name = "test", help = "Test" })
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
        assert.same({ "--style=" }, parser:get_completion("--sty"))
    end)

    it("works with a basic multi-position example", function()
        local parser = _make_simple_parser()

        -- NOTE: Simple examples
        assert.same({ "say" }, parser:get_completion("sa"))
        assert.same({ "say" }, parser:get_completion("say"))
        assert.same({ "phrase", "word", "--help" }, parser:get_completion("say "))
        assert.same({ "phrase" }, parser:get_completion("say p"))
        assert.same({ "phrase" }, parser:get_completion("say phrase"))
        assert.same({ "--repeat=", "--style=", "--help" }, parser:get_completion("say phrase "))

        -- NOTE: Beginning a --double-dash named argument, maybe (we don't know yet)
        assert.same({ "--repeat=", "--style=", "--help" }, parser:get_completion("say phrase --"))

        -- NOTE: Completing the name to a --double-dash named argument
        assert.same({ "--repeat=" }, parser:get_completion("say phrase --r"))
        -- NOTE: Completing the =, so people know that this is requires an argument
        assert.same({ "--repeat=" }, parser:get_completion("say phrase --repeat"))
        -- NOTE: Completing the value of the named argument
        assert.same({
            "--repeat=1",
            "--repeat=2",
            "--repeat=3",
            "--repeat=4",
            "--repeat=5",
        }, parser:get_completion("say phrase --repeat="))
        assert.same({
            "--repeat=5",
            "--repeat=6",
            "--repeat=7",
            "--repeat=8",
            "--repeat=9",
        }, parser:get_completion("say phrase --repeat=5"))

        assert.same({ "--style=", "--help" }, parser:get_completion("say phrase --repeat=5 "))

        -- NOTE: Asking for repeat again will not show the value (because count == 0)
        assert.same({}, parser:get_completion("say phrase --repeat=5 --repea"))

        assert.same({ "--style=", "--help" }, parser:get_completion("say phrase --repeat=5 -"))
        assert.same({ "--style=", "--help" }, parser:get_completion("say phrase --repeat=5 --"))

        assert.same({ "--style=" }, parser:get_completion("say phrase --repeat=5 --s"))

        assert.same({ "--style=" }, parser:get_completion("say phrase --repeat=5 --style"))

        assert.same(
            { "--style=lowercase", "--style=uppercase" },
            parser:get_completion("say phrase --repeat=5 --style=")
        )

        assert.same({ "--style=lowercase" }, parser:get_completion("say phrase --repeat=5 --style=l"))

        assert.same({ "--style=lowercase" }, parser:get_completion("say phrase --repeat=5 --style=lowercase"))
    end)
end)

describe("named argument", function()
    describe("++foo=bar", function()
        it("allow named argument as key", function()
            local parser = _make_style_parser("++")

            assert.same({ "++style=" }, parser:get_completion("++s"))
            assert.same({ "--help" }, parser:get_completion("++style=lowercase "))
            assert.same({}, parser:get_completion("sty"))
        end)

        it("auto-completes on a #partial argument name - 001", function()
            local parser = _make_style_parser("++")

            assert.same({}, parser:get_completion("--s", 1))
            assert.same({}, parser:get_completion("--s", 2))
        end)

        it("auto-completes on a #partial argument value - 001", function()
            local parser = _make_style_parser("++")

            assert.same({ "++style=lowercase" }, parser:get_completion("++style=low"))
            assert.same({}, parser:get_completion("++style=lowercase", 1))
            assert.same({}, parser:get_completion("++style=lowercase", 3))
            assert.same({}, parser:get_completion("++style=lowercase", 7))
            assert.same({}, parser:get_completion("++style=lowercase", 8))
            assert.same({}, parser:get_completion("++style=lowercase", 9))
            assert.same({}, parser:get_completion("++style=lowercase", 10))
            assert.same({}, parser:get_completion("++style=lowercase", 16))
        end)

        it("should only auto-complete --repeat once", function()
            local parser = _make_simple_parser(true)

            assert.same({
                "++repeat=1",
                "++repeat=2",
                "++repeat=3",
                "++repeat=4",
                "++repeat=5",
            }, parser:get_completion("say word ++repeat= ++repe", 18))
            assert.same({}, parser:get_completion("say word ++repeat= ++repe"))
        end)
    end)

    it("allow named argument as key", function()
        local parser = _make_style_parser()

        assert.same({ "--style=" }, parser:get_completion("--s"))
        assert.same({ "--help" }, parser:get_completion("--style=lowercase "))
        assert.same({ "--help" }, parser:get_completion("--style uppercase "))
        assert.same({}, parser:get_completion("sty"))
    end)

    it("auto-completes on a #partial argument name - 001", function()
        local parser = _make_style_parser()

        assert.same({}, parser:get_completion("--s", 1))
        assert.same({}, parser:get_completion("--s", 2))
    end)

    it("auto-completes on a #partial argument name - 002", function()
        local parser = _make_style_parser()

        assert.same({}, parser:get_completion("--styl", 1))
        assert.same({}, parser:get_completion("--styl", 2))
        assert.same({}, parser:get_completion("--styl", 3))
        assert.same({}, parser:get_completion("--styl", 4))
        assert.same({}, parser:get_completion("--styl", 5))
    end)

    it("auto-completes on a #partial argument name - 003", function()
        local parser = _make_style_parser()

        assert.same({}, parser:get_completion("--style", 1))
        assert.same({}, parser:get_completion("--style", 2))
        assert.same({}, parser:get_completion("--style", 3))
        assert.same({}, parser:get_completion("--style", 4))
        assert.same({}, parser:get_completion("--style", 5))
        assert.same({}, parser:get_completion("--style", 6))
    end)

    it("auto-completes on a #partial argument value - 001", function()
        local parser = _make_style_parser()

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
        local parser = cmdparse.ParameterParser.new({ help = "Test." })

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
        local parser = cmdparse.ParameterParser.new({ help = "Test." })

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

        assert.same({
            "--repeat=1",
            "--repeat=2",
            "--repeat=3",
            "--repeat=4",
            "--repeat=5",
        }, parser:get_completion("say word --repeat= --repe", 18))
        assert.same({}, parser:get_completion("say word --repeat= --repe"))
    end)

    it("suggests new named argument values based on the current value", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test" })

        _add_repeat_parameter(parser)

        assert.same({
            "--repeat=3",
            "--repeat=4",
            "--repeat=5",
            "--repeat=6",
            "--repeat=7",
        }, parser:get_completion("--repeat=3"))
    end)
end)

describe("flag argument", function()
    it("auto-completes on the dash - 001", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "-f", help = "Force it." })

        assert.same({ "-f=", "--help" }, parser:get_completion("-"), 1)
    end)

    it("auto-completes on the dash - 002", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "-f", action = "store_true", help = "Force it." })

        assert.same({ "-f", "--help" }, parser:get_completion("-"), 1)
    end)

    it("does not auto-complete if at the end of the flag - 001", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "-f", help = "Force it." })

        assert.same({}, parser:get_completion("-f", 1))
        assert.same({ "-f=" }, parser:get_completion("-f", 2))
    end)

    it("does not auto-complete if at the end of the flag - 002", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ "-f", action = "store_true", help = "Force it." })

        assert.same({}, parser:get_completion("-f", 1))
        assert.same({ "-f" }, parser:get_completion("-f", 2))
    end)

    describe("++flag examples", function()
        it("auto-completes on the dash - 001", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "+f", help = "Force it." })

            assert.same({ "+f=" }, parser:get_completion("+"), 1)
            assert.same({ "--help" }, parser:get_completion("-"), 1)
        end)

        it("auto-completes on the dash - 002", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "+f", action = "store_true", help = "Force it." })

            assert.same({ "+f" }, parser:get_completion("+"), 1)
            assert.same({ "--help" }, parser:get_completion("-"), 1)
        end)

        it("does not auto-complete if at the end of the flag - 001", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "+f", help = "Force it." })

            assert.same({}, parser:get_completion("+f", 1))
            assert.same({ "+f=" }, parser:get_completion("+f", 2))
        end)
    end)
end)

describe("nargs", function()
    describe("flag", function()
        it("works with nargs 1", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "--items", choices = { "barty", "bar", "foo" }, nargs = 1, help = "Test." })

            assert.same({ "bar", "barty" }, parser:get_completion("--items b"))
        end)

        it("works with nargs 2+", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "--items", choices = { "barty", "bar", "foo" }, nargs = 2, help = "Test." })

            assert.same({ "foo" }, parser:get_completion("--items bar f"))
        end)

        it("works with nargs *", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "--items", choices = { "barty", "bar", "foo" }, nargs = "*", help = "Test." })

            assert.same({ "foo" }, parser:get_completion("--items bar f"))
        end)

        it("works with nargs +", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "--items", choices = { "barty", "bar", "foo" }, nargs = "+", help = "Test." })

            assert.same({ "foo" }, parser:get_completion("--items bar f"))
        end)
    end)

    describe("position", function()
        it("works with nargs 1", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "items", choices = { "barty", "bar", "foo" }, nargs = 1, help = "Test." })

            assert.same({ "bar", "barty" }, parser:get_completion("b"))
        end)

        it("works with nargs 2+", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "items", choices = { "barty", "bar", "foo" }, nargs = 2, help = "Test." })

            assert.same({ "foo" }, parser:get_completion("bar f"))
        end)

        it("works with nargs *", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "items", choices = { "barty", "bar", "foo" }, nargs = "*", help = "Test." })

            assert.same({ "foo" }, parser:get_completion("bar f"))
        end)

        it("works with nargs +", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({
                "items",
                choices = { "barty", "bar", "foo" },
                nargs = "+",
                help = "Parameter test.",
            })

            assert.same({ "foo" }, parser:get_completion("bar f"))
        end)
    end)

    describe("named argument", function()
        it("does not complete with = when nargs is 2+", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test." })
            parser:add_parameter({ "--items", nargs = 2, help = "Test." })

            assert.same({ "--items" }, parser:get_completion("--ite"))

            local parser2 = cmdparse.ParameterParser.new({ help = "Test." })
            parser2:add_parameter({ "--items", nargs = 1, help = "Test." })

            assert.same({ "--items=" }, parser2:get_completion("--ite"))
        end)
    end)
end)

describe("numbered count - named argument", function()
    it("works with count = 2", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test" })
        parser:add_parameter({ name = "--foo", choices = { "bar", "fizz", "buzz" }, count = 2, help = "Test." })

        assert.same({ "--foo=" }, parser:get_completion("--fo"))
        assert.same({ "--foo=bar", "--foo=fizz", "--foo=buzz" }, parser:get_completion("--foo="))
        assert.same({ "--foo=", "--help" }, parser:get_completion("--foo=bar "))
        assert.same({ "--foo=bar", "--foo=fizz", "--foo=buzz" }, parser:get_completion("--foo=bar --foo="))
        assert.same({ "--help" }, parser:get_completion("--foo=bar --foo=bar "))
    end)
end)

describe("numbered count - named argument", function()
    it("works with count = 2", function()
        local parser = cmdparse.ParameterParser.new({ help = "Test." })
        parser:add_parameter({ name = "--foo", choices = { "bar", "fizz", "buzz" }, count = 2, help = "Test." })

        assert.same({ "--foo=" }, parser:get_completion("--fo"))
        assert.same({ "--foo=bar", "--foo=fizz", "--foo=buzz" }, parser:get_completion("--foo="))
        assert.same({ "--foo=", "--help" }, parser:get_completion("--foo=bar "))
        assert.same({ "--foo=bar", "--foo=fizz", "--foo=buzz" }, parser:get_completion("--foo=bar --foo="))
        assert.same({ "--help" }, parser:get_completion("--foo=bar --foo=bar "))
    end)
end)

describe("* count", function()
    describe("simple", function()
        it("works with position arguments", function()
            local parser = cmdparse.ParameterParser.new({ help = "Test" })
            parser:add_parameter({ name = "thing", choices = { "foo" }, count = "*", help = "Test." })

            assert.same({ "foo", "--help" }, parser:get_completion(""))
            assert.same({ "foo" }, parser:get_completion("fo"))
            assert.same({ "foo" }, parser:get_completion("foo"))
            assert.same({ "foo", "--help" }, parser:get_completion("foo "))
            assert.same({ "foo" }, parser:get_completion("foo fo"))
            assert.same({ "foo" }, parser:get_completion("foo foo"))
            assert.same({ "foo", "--help" }, parser:get_completion("foo foo "))
            assert.same({ "foo" }, parser:get_completion("foo foo foo"))
            assert.same({ "foo", "--help" }, parser:get_completion("foo foo foo "))
        end)
    end)
end)

describe("dynamic argument", function()
    it("works even if matches use spaces", function()
        local parser = cmdparse.ParameterParser.new({ name = "top_test", help = "Test" })
        local subparsers = parser:add_subparsers({ destination = "commands", help = "All main commands." })
        local say_parser = subparsers:add_parser({ name = "say", help = "Say something." })
        local inner_subparsers = say_parser:add_subparsers({ destination = "thing_subparsers", help = "Test." })

        local dynamic = inner_subparsers:add_parser({
            name = "dynamic_thing",
            choices = function()
                return { "item with spaces", "cc", "zzz", "lazers" }
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
            help = "Test.",
        })

        assert.same({ "item with spaces" }, parser:get_completion('say "item "'))
        assert.same({ "branch" }, parser:get_completion('say "item with spaces" different b'))
    end)

    it("works with positional arguments", function()
        local parser = cmdparse.ParameterParser.new({ name = "top_test", help = "Test" })
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
        thing:add_parameter({ name = "last_thing", choices = { "another", "last" }, help = "Test." })

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
            help = "Test.",
        })

        -- NOTE: We don't complete the next subparsers because required
        -- parameter(s) from the `say` subparser have no been satisfied yet.
        --
        assert.same({ "a", "asteroid", "bb", "tt", "--help" }, parser:get_completion("say "))
        -- IMPORTANT: Notice we do not include `ab` in the completion because
        -- the `thing` argument is required and must be satisfied first before
        -- we can continue to the subparser.
        --
        assert.same({ "a", "asteroid" }, parser:get_completion("say a"))
        assert.same({ "ab", "cc", "lazers", "thing_parser", "zzz", "--help" }, parser:get_completion("say a "))
        assert.same({ "ab", "cc", "lazers", "thing_parser", "zzz", "--help" }, parser:get_completion("say tt "))
        assert.same({ "another", "last", "--help" }, parser:get_completion("say a thing_parser "))

        assert.same({ "different", "--help" }, parser:get_completion("say ab "))
        assert.same({ "branch", "here", "--help" }, parser:get_completion("say ab different "))
    end)
end)
