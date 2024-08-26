- TODO: Add "TODO: (you)" in various places in the code-base
- Add a doc/news.txt
- Add doc/ or a GitHub Wiki
- make sure the lualine configuration color + options work as expected
- Do existing TODO notes

- Add luarocks auto-release integration

- Consider moving the api file to init.lua. As long as it does not auto-import

- Add unittests for telescope
 - https://github.com/nvim-lua/plenary.nvim/issues?q=wait+event
 - https://github.com/nvim-lua/plenary.nvim/issues/424
 - https://github.com/nvim-lua/plenary.nvim/commit/1252cb3344d3a7bf20614dca21e7cf17385eb1de
 - https://github.com/nvim-lua/plenary.nvim/pull/447/files
 - https://github.com/nvim-lua/plenary.nvim/pull/426

Remember what the rockspec file is for

- When there's no arguments written yet, auto-complete the first thing(s)
- Add unittest to make sure that an optional, repeatable --flag / --named=arg can be used in multiple places. e.g.

```lua
local style = {count=3, ...}
local tree = { {style}, {style}, }
```

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

- Write instructions on what people should do when they use the template

- Blow away all of the commits. Clean it up


command-line parser needs to handle this case
foo bar --thing --thing --thing blah
 - Where blah is after --thing, which is count="*"

## Checklist

- ...provide vimdoc, so that users can read your plugin's documentation in Neovim, by entering :h {plugin}.
 - https://github.com/kdheepak/panvimdoc

- Lazy load everything. Make sure Lazy shows it loading really fast

- Change the template to an auto-generator to describe what you want to use?

 - Move the argparse + autocomplete stuff to its own lua package
 - Include the lua package + vendorize it here

TODO: Add "TODO: (you)" in various places in the code-base

- Make sure the issue templates are good
