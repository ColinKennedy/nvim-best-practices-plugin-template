- Add argparse solution
- Add auto-completion function
- replace all plugin-template with plugin-name instead
- replace all plugin_template with plugin_name instead
- replace all PluginTemplate with PluginName instead
- Health check implementation

- argparse - allow repeated flags, maybe?
- Make sure named auto-complete works not just for keys but also for values

- https://github.com/marketplace/actions/lua-typecheck-action
- https://github.com/marketplace/actions/lua-typecheck-action
- https://github.com/jeffzi/llscheck
- https://github.com/mpeterv/luacheck

- Add unittests for the auto-complete

- Add `<Plug>` options
- Add Lua API functions
- Don't provide a setup(), instead "smartly" implement it
- Lazy load everything

- https://github.com/lua-fmt/lua-fmt
- https://github.com/Koihik/LuaFormatter

- Validate configurations
 - Use their code

- Integrations
 - Vim health
 - Telescope
 - Lualine

- Add internal unittests

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


{
  argument_order = {
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

## Checklist

--- ...leverage LuaCATS annotations, along with lua-language-server to catch potential bugs in your CI before your plugin's users do.
--- ...gather subcommands under scoped commands and implement completions for each subcommand.

- ...provide :h <Plug> mappings to allow users to define their own keymaps.


- Cleanly separate configuration and initialization.
- Automatically initialize your plugin (smartly), with minimal impact on startup time (see the next section).

- ...think carefully about when which parts of your plugin need to be loaded.
 - Make sure plugin logic initializes once, lazy-loaded
- ...validate configs.

- ...provide health checks in lua/{plugin}/health.lua.

- ...use SemVer to properly communicate bug fixes, new features, and breaking changes.

- ...provide vimdoc, so that users can read your plugin's documentation in Neovim, by entering :h {plugin}.
 - https://github.com/kdheepak/panvimdoc

--- ...automate testing as much as you can.
--- ...use busted for testing, which is a lot more powerful.

- For example, it might be useful to add a telescope.nvim extension or a lualine component.
