- Update plugin/ folder with the new argparse API

- Support `--foo=bar` syntax, in general
 - Auto-complete should include `--foo=` if a flag requires `nargs=1`

- Rename "argument" to "option", for consistency
- Allow parsers to have `choices` names
- Allow all `choices` to get context information (current argument, current text, etc etc)
- Rename all `description` to `help` instead

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

- Add namespaces to all of the argparse / argparse2 types

Replace all foo._bar code with actual accessors / functions

- replace all `_subparsers` with a get_subparsers() method
- replace the subparsers / parser nested for-loop with a "parser iterator" instead
- Add unittests for invalid arguments. e.g. `say word 'asdfasd`

- Add dotted namespace types to the docstrings
