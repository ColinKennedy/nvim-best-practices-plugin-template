- Make sure the issue templates are good
 - https://github.com/folke/which-key.nvim/issues/new?assignees=&labels=bug&projects=&template=bug_report.yml&title=bug%3A+
 - https://github.com/folke/which-key.nvim/issues/new?assignees=&labels=enhancement&projects=&template=feature_request.yml&title=feature%3A+

- make sure the lualine configuration color + options work as expected

- Add telescope configuration
 - colors, I guess

- template - Add explanation on how to get the logs from a file, easily

https://github.com/nvim-neorocks/nvim-best-practices/commits/master/runtime/doc/news.txt.atom
https://github.com/neovim/neovim/commits/master/runtime/doc/news.txt.atom
https://github.com/neovim/neovim/blob/master/.github/workflows/lintcommit.yml
https://github.com/neovim/neovim/issues/new?assignees=&labels=bug&projects=&template=bug_report.yml
https://github.com/folke/which-key.nvim/blob/main/.github/ISSUE_TEMPLATE/config.yml


https://github.com/neovim/neovim/blob/master/.github/workflows/news.yml

- Change lua types to be dotted. Maybe.

- Add luarocks auto-release integration

- https://github.com/marketplace/actions/lua-typecheck-action
- https://github.com/jeffzi/llscheck
- https://github.com/mpeterv/luacheck


- https://github.com/lua-fmt/lua-fmt
- https://github.com/Koihik/LuaFormatter



- When there's no arguments written yet, auto-complete the first thing(s)
- Add unittest to make sure that an optional, repeatable --flag / --named=arg can be used in multiple places. e.g.

```lua
local style = {count=3, ...}
local tree = { {style}, {style}, }
```

- Replace CLI -> command
- Replace command -> runner

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
 - Allow "any" argument somehow

- Add unittests for failed stuff (bad commands with incorrect arguments)
 - command running
 - auto-complete

- Make sure as much as possible is defer evaluated
 - Does Lua import parent init.lua files?

- autocomplete notes
 - when nothing is written, show the auto-complete

- Re-enable the other unittests

- Add argparse solution
 - Move to a luarocks module and include it here
  - Vendor the argparse in case the user doesn't have it installed
- Add auto-completion function





- Add doc/ or a GitHub Wiki
    - Explain the folder structure

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
