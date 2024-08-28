- Make sure the auto-generated documentation looks good
   - Leave notes on how to make it from scratch

- Change copy-logs to be async

- Change the tests so that unittests cannot be influenced by a user's personal configuration
    - vim.env.XDG_CONFIG_HOME = "test/xdg/config/"
    - vim.env.XDG_STATE_HOME = "test/xdg/local/state/"
    - vim.env.XDG_DATA_HOME = "test/xdg/local/share/"
    - https://hiphish.github.io/blog/2024/01/29/testing-neovim-plugins-with-busted/
- Make sure the documentation auto-generates correctly and the issue templates refer to it correctly

- TODO: Add "TODO: (you)" in various places in the code-base
- Do existing TODO notes

- Add luarocks auto-release integration

- Make sure the README.md and configuration are correct values

- Add tags to various tests
- Consider moving the api file to init.lua. As long as it does not auto-import

- Add unittests for telescope
 - https://github.com/nvim-lua/plenary.nvim/issues?q=wait+event
 - https://github.com/nvim-lua/plenary.nvim/issues/424
 - https://github.com/nvim-lua/plenary.nvim/commit/1252cb3344d3a7bf20614dca21e7cf17385eb1de
 - https://github.com/nvim-lua/plenary.nvim/pull/447/files
 - https://github.com/nvim-lua/plenary.nvim/pull/426

Remember what the rockspec file is for

- Write instructions on what people should do when they use the template

- Blow away all of the commits. Clean it up


## Checklist

- ...provide vimdoc, so that users can read your plugin's documentation in Neovim, by entering :h {plugin}.
 - https://github.com/kdheepak/panvimdoc

- Lazy load everything. Make sure Lazy shows it loading really fast

TODO: Add "TODO: (you)" in various places in the code-base

- Remove this file
