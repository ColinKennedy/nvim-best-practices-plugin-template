- Change the file structure to make it easier to generate API documentation
 - Make  specific "types" file so that it's included in the API
  - e.g. the configuration

- Add warning to the bottom of the generated API file - "dont change this file"

- Classes need to generate tags too
- Add whitespace between sections / class / function information. It's too
bunched up.

```
---@class plugin_template.LoggingConfiguration
---     Control whether or not logging is printed to the console or to disk.
---@field level (
---     | "trace"
---     | "debug"
---     | "info"
---     | "warn"
---     | "error"
---     | "fatal"
---     | vim.log.levels.DEBUG
---     | vim.log.levels.ERROR
---     | vim.log.levels.INFO
---     | vim.log.levels.TRACE
---     | vim.log.levels.WARN)?
---     Any messages above this level will be logged.
```

This doesn't parse as expected

- Add API documentation github CI workflow
 - Have it run on each major / minor, I guess
- Add command to Makefile for making user / API documentation

- Follow up on - https://github.com/jeffzi/llscheck/issues/7#issuecomment-2352981951

- Get unittests to pass
- Auto-complete should include `--foo=` if a flag requires `nargs=1` but `--foo` if `nargs` is different

- Allow all `choices` to get context information (current argument, current text, etc etc)

- "works with nested parsers where a parent also defines a default" is bugged. Selecting a subparser should immediately get its value(s).

- Somehow the `--style=low|cursor|` auto-completion isn't working anymore. Fix!

- Remove subcommand-related files
 - Make sure the GitHub wiki + documentation still works

- Add the wiki pages to this repository
 - Make sure the documentation tellsthe user to delete this folder

- Make sure help text allows a parser choices() to be represented as text

- Make sure that a "dynamic plugin" command-line parse is possible. e.g. Telescope

- Is there really any need to auto-complete the short flags if the long flag is there? Remove?

- Add a configuration option to disable --help / -h from auto-completion

- Need a test for when a subparser is the last argument
 - When the subparser is required it should error. If not then forget it
 - Auto-complete should work as expected
- Add a check when user does `--foo=bar` but foo requires 2+ arguments (the
= would be syntactically incorrect in that case)
- Consider renaming `nargs` to `elements_count` or something

- Make a unittest for nargs where it fails to find values and errors ou
 - scenario A: nargs stops because a flag/named argument is encountered
 - scenario B: the argument has a known set of choices and no choice matches

- Add a unittest to makes sure that position `choices` can maintain another table and remove possible matches each time the argument is used
 - Same test but for flag arguments

- Allow ++foo arguments instead of --

Replace all foo._bar code with actual accessors / functions

- replace all `_subparsers` with a get_subparsers() method
- replace the subparsers / parser nested for-loop with a "parser iterator" instead
- Add unittests for invalid arguments. e.g. `say word 'asdfasd`

- Adjust all docstrings so they're as LuaCATS expects



- Allow different matching schemes. e.g. startswith is the default. But maybe
allow fuzzy matching too

- Make sure that if the user provides incorrect input that the concise help message is shown
 - Make sure they know that explicit --help shows the full message



- See if there's a way to make llscheck work with busted attributes
 - https://github.com/jeffzi/llscheck/issues/7



## Extra Features
- lemmy-help to generate vimdocs from .lua files
- Check files for syntax errors using tree-sitter parsers (via Neovim)?
