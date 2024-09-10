- Update plugin/ folder with the new argparse API

- Support `--foo=bar` syntax, in general
 - Auto-complete should include `--foo=` if a flag requires `nargs=1`

- Allow parsers to have `choices` names
- Allow all `choices` to get context information (current argument, current text, etc etc)
- Rename all `description` to `help` instead

- Make sure help text allows a parser choices() to be represented as text

- Consider renaming `nargs` to `elements_count` or something

- Add a unittest to makes sure that position `choices` can maintain another table and remove possible matches each time the argument is used
 - Same test but for flag arguments


- Allow ++foo arguments instead of --

- Add namespaces to all of the argparse / argparse2 types

Replace all foo._bar code with actual accessors / functions

- replace all `_subparsers` with a get_subparsers() method
- replace the subparsers / parser nested for-loop with a "parser iterator" instead
- Add unittests for invalid arguments. e.g. `say word 'asdfasd`

- Add dotted namespace types to the docstrings
