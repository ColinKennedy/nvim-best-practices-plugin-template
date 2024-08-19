- Finish goodnight-moon
- Do existing TODO notes
- Get all tests to pass again
- Add unittests for failed stuff (bad commands with incorrect arguments)
 - command running
 - auto-complete

- Clean up the API files
 - Make sure repeat + style does something
 - Add unittests for it

- Change lua types to be dotted. Maybe.

- Add unittes for multiple escaped \ characters
- autocomplete notes
 - when nothing is written, show the auto-complete

- Re-enable the other unittests

- Add argparse solution
 - Move to a luarocks module and include it here
  - Vendor the argparse in case the user doesn't have it installed
- Add auto-completion function

- Add missing lua-busted test tags

- Rename from plugin-name to plugin-template

- replace all plugin-template with plugin-name instead
- replace all plugin_template with plugin_name instead
- replace all PluginTemplate with PluginName instead

- argparse - allow repeated flags, maybe?
- Make sure named auto-complete works not just for keys but also for values

- Add luarocks auto-release integration

- https://github.com/marketplace/actions/lua-typecheck-action
- https://github.com/marketplace/actions/lua-typecheck-action
- https://github.com/jeffzi/llscheck
- https://github.com/mpeterv/luacheck

- Add unittests for the auto-complete


- Add doc/ or a GitHub Wiki
    - Explain the folder structure


- Add `<Plug>` options
- Add Lua API functions

- https://github.com/lua-fmt/lua-fmt
- https://github.com/Koihik/LuaFormatter

- Integrations
 - Telescope
 - Lualine
 - For example, it might be useful to add a telescope.nvim extension or a lualine component.

- Write instructions on what people should do when they use the template
- Make sure the issue templates are good

- Blow away all of the commits. Clean it up

- auto-complete behavior
 - argument order
  - default
   - positional then flags then double flags then named flags
   - positional then (flags or double flags or named flags, any order)
   - positional in any order flags or double flags or named flags, any order
   - positional in any order but cannot be intermixed with the other flags
 - arguments repetition
   - exactly 1 / exactly 2 / etc
   - 0-or-more
   - repeatable


```lua
    {
        hello_world = {
            ["arbitrary-thing"] = {
                {
                    {
                        {type=completion.Flag, name="-a"},
                        {type=completion.Flag, name="-b"},
                        {type=completion.Flag, name="-c"},
                        {type=completion.Flag, name={"-f", "--force"}},
                        {type=completion.Flag, name={"-v", "--verbose"}, count="*"},
                    },
                }
            }
            say = {
                {"phrase", "word"},
                {
                    completion.PositionalArgument.one,
                    {
                        {
                            choices=function() end, count=1
                            name="repeat",
                            type=completion.NamedArgument,
                        },
                        {type=completion.NamedArgument, name="style", choices={"lowercase", "uppercase"}},
                    },
                }
            }
        },
    }
```


{
argument_order = {
    overall_order = {
        positional,
        {named, single_flag, double_flag},
    },
}

{ argument_order = {
    overall_order = {
      positional,
      {named, single_flag, double_flag},
    },
    -- If not defined or empty table, then positionals can be in any order
    -- If a positional is unspecified (but others are) assume any order
    --
    -- positional order needs to validate each item so there's not accidental duplicates
    --
    positional_order = {
      {before, after, thing},
      {another, {multiple, choice, allowed, here}},
    }
  }
}

- can use the named arguments exactly once
{
  repetition_behavior = {named_arguments = {repeat = 1, style = 1}},
}


- can use the named arguments exactly once
{
  repetition_behavior = {named_arguments = {repeat = 1, style = 1}},
}

command-line parser needs to handle this case

foo bar --thing --thing --thing blah
 - Where blah is after --thing, which is count="*"

## Checklist

- ...provide :h <Plug> mappings to allow users to define their own keymaps.

- ...use SemVer to properly communicate bug fixes, new features, and breaking changes.

- ...provide vimdoc, so that users can read your plugin's documentation in Neovim, by entering :h {plugin}.
 - https://github.com/kdheepak/panvimdoc

- Lazy load everything. Make sure Lazy shows it loading really fast

- A form to describe what you want to use?

- Move the CLI stuff into the API, maybe

- Fix the configuration typehints

- Auto-complete
 - Get it working
 - Move the argparse + autocomplete stuff to its own lua package
 - Include the lua package + vendorize it here
 - Add auto-complete unittests

