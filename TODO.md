- Update plugin/ folder with the new argparse API

- Support `--foo=bar` syntax, in general
 - Auto-complete should include `--foo=` if a flag requires `nargs=1`

- Rename all `description` to `help` instead

- replace all `_subparsers` with a get_subparsers() method
- replace the subparsers / parser nested for-loop with a "parser iterator" instead
- Add unittests for invalid arguments. e.g. `say word 'asdfasd`

- Add dotted namespace types to the docstrings
