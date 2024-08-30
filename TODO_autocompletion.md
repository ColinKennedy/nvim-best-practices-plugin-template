- Add unittest to make sure that an optional, repeatable --flag / --named=arg can be used in multiple places. e.g.
- Allow "any" positional argument as an option

```lua
local style = {count=3, ...}
local tree = { {style}, {style}, }
```

- allow for positional choices
- Create a tree structure for auto-completion

- Do existing TODO notes
- /home/selecaoone/repositories/personal/.config/nvim/bundle/nvim-best-practices-plugin-template/lua/plugin_template/_cli/completion.lua

- Try one more time to get completion working
 - Add unitests for different cursor positions along the completion results
  - positional argument
   - before argument
   - in argument
   - after argument (no space)
   - after argument (space)
  - named argument
   - before argument
   - in argument
   - after argument (no space)
   - after argument (space)
  - flag
   - before argument
   - in argument
   - after argument (no space)
   - after argument (space)
  - named argument choices
   - Make sure it works when cursor is in the middle of a command string
 - required flag / named arguments
 - Make sure cursor position works with named arguments as expected
 - Allow "any" argument, somehow

- Add unittests for failed stuff (bad commands with incorrect arguments)
 - command running
 - auto-complete

- autocomplete notes
 - when nothing is written, show the auto-complete

- Add argparse solution
 - Move to a luarocks module and include it here
  - Vendor the argparse in case the user doesn't have it installed
- Add auto-completion function

-- TODO: We assume here that double flags, --foo, do not exist.
-- There is only -f or --foo=bar. We should probably allow --foo to
-- exist in the future.
--

command-line parser needs to handle this case
foo bar --thing --thing --thing blah
 - Where blah is after --thing, which is count="*"

 - Move the argparse + autocomplete stuff to its own lua package
 - Include the lua package + vendorize it here

TODO: Remove this file
