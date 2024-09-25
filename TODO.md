```
- nargs 2
 - append
- nargs *
 - append
- nargs +
 - append
  - --foo bar --foo buzz = {bar, buzz}

```

- Try to get the CI working for Linux / Mac / Windows again

- Fix all `choices()` calls. They're missing context

- make sure namesapce aggregation works as expected (default [set] vs store_true / store_false / append / etc)

- Make sure nargs works as it does in Python, basically
- Make sure nargs 2 and action append get proper parsed data
- Double check how Python handles action + type at the same time. e.g. how does action (set, store_true, append, etc) work with type (make sure values are converted to number and stuff as expected)

- remove private variable accesses

- Add `context` key to choices so people know why the choices are being requested

- validation code should include choices if there is some
- Do a round of finishing TODO notes

- Make sre the CI works
 - llscheck
 - release
 - test
 --- lintcommit
 --- luacheck
 --- news
 --- stylua

- Consider changing argparse so that it registers any argument that starts with
a non-alpha / ' / " as a flag argument. Instead of the current setup which only
allows for - or +

- If a named arguiment is an nargs=1 argument then it should auto-complete to be --foo=, I guess
 - If it it's nargs=2+ then it should auto-complete not with =

`PluginTemplate hello-world say phrase --repeat=`
```
E5108: Error executing Lua function: ...ate/lua/plugin_template/_commands/hello_world/parser.lua:12: attempt to index local 'data' (a nil va
lue)
stack traceback:
        ...ate/lua/plugin_template/_commands/hello_world/parser.lua:12: in function 'choices'
        ...s-plugin-template/lua/plugin_template/_cli/argparse2.lua:221: in function '_is_single_nargs_and_named_parameter'
        ...s-plugin-template/lua/plugin_template/_cli/argparse2.lua:228: in function '_has_satisfying_value'
        ...s-plugin-template/lua/plugin_template/_cli/argparse2.lua:331: in function '_compute_exact_flag_match'
        ...s-plugin-template/lua/plugin_template/_cli/argparse2.lua:1641: in function '_compute_matching_parsers'
        ...s-plugin-template/lua/plugin_template/_cli/argparse2.lua:1381: in function '_get_completion'
        ...s-plugin-template/lua/plugin_template/_cli/argparse2.lua:1835: in function '_get_subcommand_completion'
        ...gin-template/lua/plugin_template/_cli/cli_subcommand.lua:185: in function <...gin-template/lua/plugin_template/_cli/cli_subcomman
d.lua:182>
```

Typing `-` or `--` doesn't auto-complete to `--repeat`

- Follow up on - https://github.com/jeffzi/llscheck/issues/7#issuecomment-2352981951

- Auto-complete should include `--foo=` if a flag requires `nargs=1` but `--foo` if `nargs` is different

- Allow all `choices` to get context information (current argument, current text, etc etc)

- "works with nested parsers where a parent also defines a default" is bugged. Selecting a subparser should immediately get its value(s).

- Remove subcommand-related files
 - Make sure the GitHub wiki + documentation still works

- Add the wiki pages to this repository
 - Make sure the documentation tellsthe user to delete this folder

- Add a configuration option to disable --help / -h from auto-completion

- Need a test for when a subparser is the last argument
 - When the subparser is required it should error. If not then forget it
 - Auto-complete should work as expected
- Add a check when user does `--foo=bar` but foo requires 2+ arguments (the
= would be syntactically incorrect in that case)
- Consider renaming `nargs` to `elements_count` or something

- Add a unittest to makes sure that position `choices` can maintain another table and remove possible matches each time the argument is used
 - Same test but for flag arguments

Replace all foo._bar code with actual accessors / functions

- replace all `_subparsers` with a get_subparsers() method
- replace the subparsers / parser nested for-loop with a "parser iterator" instead
- Add unittests for invalid arguments. e.g. `say word 'asdfasd`



- Allow different matching schemes. e.g. startswith is the default. But maybe
allow fuzzy matching too

- Make sure that if the user provides incorrect input that the concise help message is shown
 - Make sure they know that explicit --help shows the full message


- Make sure API docs generation works + user docs

## Extra Features
- Check files for syntax errors using tree-sitter parsers (via Neovim)?


Update news.txt at the end
 - Make sure to increment the version
