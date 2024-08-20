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


- Do existing TODO notes
- /home/selecaoone/repositories/personal/.config/nvim/bundle/nvim-best-practices-plugin-template/lua/plugin_template/_cli/completion.lua

- Add unittests for failed stuff (bad commands with incorrect arguments)
 - command running
 - auto-complete

- Change lua types to be dotted. Maybe.

- autocomplete notes
 - when nothing is written, show the auto-complete

- Re-enable the other unittests

- Add argparse solution
 - Move to a luarocks module and include it here
  - Vendor the argparse in case the user doesn't have it installed
- Add auto-completion function

- Add luarocks auto-release integration

- https://github.com/marketplace/actions/lua-typecheck-action
- https://github.com/marketplace/actions/lua-typecheck-action
- https://github.com/jeffzi/llscheck
- https://github.com/mpeterv/luacheck

- Add unittests for the auto-complete


- Add doc/ or a GitHub Wiki
    - Explain the folder structure

- https://github.com/lua-fmt/lua-fmt
- https://github.com/Koihik/LuaFormatter

- Integrations
 - Telescope
 - Lualine
 - For example, it might be useful to add a telescope.nvim extension or a lualine component.

- Write instructions on what people should do when they use the template
- Make sure the issue templates are good

- Blow away all of the commits. Clean it up


command-line parser needs to handle this case
foo bar --thing --thing --thing blah
 - Where blah is after --thing, which is count="*"

## Checklist

- ...provide vimdoc, so that users can read your plugin's documentation in Neovim, by entering :h {plugin}.
 - https://github.com/kdheepak/panvimdoc

- Lazy load everything. Make sure Lazy shows it loading really fast

- Change the template to an auto-generator to describe what you want to use?

- Move the CLI stuff into the API, maybe

- Auto-complete
 - Get it working
 - Move the argparse + autocomplete stuff to its own lua package
 - Include the lua package + vendorize it here
 - Add auto-complete unittests

