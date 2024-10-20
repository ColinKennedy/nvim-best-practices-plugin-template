## Round 1
- Do TODO notes

- remove private variable accesses

- replace all `_subparsers` with a get_subparsers() method

```
nargs=0 + position should error
nargs for store actions must be != 0; if you have nothing to store, actions such as store true or store const may be more approp
```

- What happens if a user provides a 1-or-more / 0-or-more and then has a flag in the middle?
 - PluginTemplate hello-world say phrase sadfasfasdf asdfsfd --repeat=3 sfdasfdasfddttt
 - should it error ot just append the next position to the previous one

- Make sure auto-completion does not spam errors to the user if they give incorrect input


## Round 2
- Need a test for when a subparser is the last argument
 - When the subparser is required it should error. If not then forget it
 - Auto-complete should work as expected
- Consider renaming `nargs` to `arguments_count` or something

- Add --help argument configuration


## Round 3
- Make positional * count as required=false
- Support position + count

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
 - Passing workflow badges
 - Static badges

Consider more badges
https://github.com/azratul/live-share.nvim?tab=readme-ov-file

- Consider changing argparse so that it registers any argument that starts with
a non-alpha / ' / " as a flag argument. Instead of the current setup which only
allows for - or +

- Follow up on - https://github.com/jeffzi/llscheck/issues/7#issuecomment-2352981951

- Make sure subcommand-related API still works
 - Make sure the GitHub wiki + documentation still works

- Add a configuration option to disable --help / -h from auto-completion


- Allow different matching schemes. e.g. startswith is the default. But maybe
allow fuzzy matching too

- Make sure API docs generation works + user docs

## Extra Features
- Check files for syntax errors using tree-sitter parsers (via Neovim)?


Update news.txt at the end
 - Make sure to increment the version
