--- Parse `"hello-world say"` from COMMAND mode and run it.
---
--- @module 'plugin_template._commands.say.cli'
---

local argparse = require("plugin_template._cli.argparse")
local argparse_helper = require("plugin_template._cli.argparse_helper")
local configuration_ = require("plugin_template._core.configuration")
local constant = require("plugin_template._commands.hello_world.say.constant")
local say_command = require("plugin_template._commands.hello_world.say.command")
local tabler = require("plugin_template._core.tabler")

local M = {}

--- Pull out the relevant arguments from the user's COMMAND settings.
---
--- @param arguments (FlagArgument | PositionArgument | NamedArgument)[]
---     All of the user's arguments.
--- @param configuration PluginTemplateConfiguration?
---     Control how many times the phrase is said and the text's display.
--- @return string[]?
---     All text that the user wrote, if any.
--- @return number?
---     The number of times to print the phrase / word.
--- @return ("lowercase" | "uppercase")?
---     A modifier that runs before the text is printed.
---
local function _get_data_details(arguments, configuration)
    local phrases = {}

    local style = tabler.get_value(configuration, { "commands", "hello_world", "say", "style" }) or "lowercase"
    --- @cast style ("lowercase" | "uppercase")?

    if not style then
        _LOGGER.fmt_warn('Configuration "%s" has no style.', configuration)

        return {}
    end

    local default_repeat = tabler.get_value(configuration, { "commands", "hello_world", "say", "repeat" }) or 1
    --- @cast default_repeat number

    local found_repeat = false
    local repeat_ = nil

    for _, argument in ipairs(arguments) do
        if argument.argument_type == argparse.ArgumentType.position then
            tabler.extend(phrases, vim.fn.split(argument.value, " "))
        end

        if argument.argument_type == argparse.ArgumentType.named then
            if argument.name == "repeat" then
                if not found_repeat then
                    repeat_ = argument.value
                    found_repeat = true
                else
                    repeat_ = repeat_ + argument.value
                end
            end

            if argument.name == "style" then
                style = argument.value
            end
        end
    end

    repeat_ = repeat_ or default_repeat

    return { phrases, repeat_, style }
end

--- Parse `"hello-world say"` from COMMAND mode and run it.
---
--- @param data ArgparseResults All found user data.
---
function M.run_say(data)
    local subcommand = data.arguments[1].value
    data = argparse_helper.lstrip_arguments(data, 2)

    local configuration = configuration_.resolve_data()

    if subcommand == constant.Subcommand.phrase then
        local phrase, repeat_, style = unpack(_get_data_details(data.arguments, configuration))
        say_command.run_say_phrase(phrase, repeat_, style)

        return
    end

    if subcommand == constant.Subcommand.word then
        local phrase, repeat_, style = unpack(_get_data_details(data.arguments, configuration))
        say_command.run_say_word(phrase[1], repeat_, style)

        return
    end

    vim.notify(
        string.format(
            'say command failed. Got "%s", expected "%s" subcommand.',
            subcommand,
            vim.inspect({ constant.Subcommand.phrase, constant.Subcommand.word })
        ),
        vim.log.levels.ERROR
    )
end

return M
