- Update plugin/ folder with the new argparse API

- Support `--foo=bar` syntax, in general
 - Auto-complete should include `--foo=` if a flag requires `nargs=1`

- Allow parsers to have `choices` names
- Rename all `description` to `help` instead

- Add a unittest to makes sure that position `choices` can maintain another table and remove possible matches each time the argument is used
 - Same test but for flag arguments

- replace all `_subparsers` with a get_subparsers() method
- replace the subparsers / parser nested for-loop with a "parser iterator" instead
- Add unittests for invalid arguments. e.g. `say word 'asdfasd`

- Add dotted namespace types to the docstrings
