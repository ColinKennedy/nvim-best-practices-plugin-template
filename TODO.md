- Try to get the CI working for Linux / Mac / Windows again

- Add a unittest to makes sure that position `choices` can maintain another table and remove possible matches each time the argument is used
 - Same test but for flag arguments
- Allow all `choices` to get context information (current argument, current text, etc etc)

- remove private variable accesses

- Do a round of finishing TODO notes

- Make sure the README.md commands work

- The documentation.yml `tags` CI runner doesn't work. Fix!

- Consider allowing unicode things

- Make sure the CI works
 - llscheck
 - release
 - test
 --- lintcommit
 --- luacheck
 --- news
 --- stylua

- Add badges to the README.md
 - RSS
 - Stylua
 - etc

- Consider changing argparse so that it registers any argument that starts with
a non-alpha / ' / " as a flag argument. Instead of the current setup which only
allows for - or +

- If a named arguiment is an nargs=1 argument then it should auto-complete to be --foo=, I guess
 - If it it's nargs=2+ then it should auto-complete not with =

Typing `-` or `--` doesn't auto-complete to `--repeat`

- Follow up on - https://github.com/jeffzi/llscheck/issues/7#issuecomment-2352981951

- "works with nested parsers where a parent also defines a default" is bugged. Selecting a subparser should immediately get its value(s).

- Remove subcommand-related files
 - Make sure the GitHub wiki + documentation still works

- Add the wiki pages to this repository
 - Make sure the documentation tellsthe user to delete this folder

- Add a configuration option to disable --help / -h from auto-completion

- Need a test for when a subparser is the last argument
 - When the subparser is required it should error. If not then forget it
 - Auto-complete should work as expected
- Consider renaming `nargs` to `elements_count` or something

- replace all `_subparsers` with a get_subparsers() method
- replace the subparsers / parser nested for-loop with a "parser iterator" instead
- Add unittests for invalid arguments. e.g. `say word 'asdfasd`


- Allow different matching schemes. e.g. startswith is the default. But maybe
allow fuzzy matching too

- Make sure they know that explicit --help shows the full message


- Make sure API docs generation works + user docs

## Extra Features
- Check files for syntax errors using tree-sitter parsers (via Neovim)?


Update news.txt at the end
 - Make sure to increment the version
