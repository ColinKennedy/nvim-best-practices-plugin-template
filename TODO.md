- Make sure the auto-generated documentation looks good
   - Leave notes on how to make it from scratch

--style doesn't autocomplete anymore. Fix

- Change the tests so that unittests cannot be influenced by a user's personal configuration
    - vim.env.XDG_CONFIG_HOME = "test/xdg/config/"
    - vim.env.XDG_STATE_HOME = "test/xdg/local/state/"
    - vim.env.XDG_DATA_HOME = "test/xdg/local/share/"
    - https://hiphish.github.io/blog/2024/01/29/testing-neovim-plugins-with-busted/
- Make sure the documentation auto-generates correctly and the issue templates refer to it correctly

- Add arbitrary-thing support
    - plugin
        - run / complete
    - spec
    - lualine configuration
    - Telescope
    - health

- TODO: Add "TODO: (you)" in various places in the code-base

- Add luarocks auto-release integration

- Document how to do a release

Remember what the rockspec file is for

- Write instructions on what people should do when they use the template

- Blow away all of the commits. Clean it up


## Checklist

- ...provide vimdoc, so that users can read your plugin's documentation in Neovim, by entering :h {plugin}.
 - https://github.com/kdheepak/panvimdoc

- Lazy load everything. Make sure Lazy shows it loading really fast

- Do existing TODO notes

- Remove this file

- Remove the TODO_autocompletion file, too
