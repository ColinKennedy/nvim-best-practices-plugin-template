- Allow evaluation of vimscript / shell, e.g.
    - important, make sure spaces are not skipped (e.g. `python (foo)` is not an expression but `python(foo)` is)
    - vimscript :()
    - shell $()
    - python Python()
    - Lua Lua()
     - https://github.com/neovim/neovim/commit/d5ae5c84e94a2b15374ee0c7e2f4444c161a8a63
     - get_completions()
    - Shell variables - ${}

    - When expanded, use their data directly. OR if it's around quotes, use it as quotes
        - Escape expressions inside of single quotes. But not double quotes
    - Add expression handler API
    - Make sure expression auto-completion API run even if the closing ) is not found!
    - Make sure users can escape expression-ending text. e.g. they should be allowed to do $(foo $(bar)) to run a shell command within a command expression

- Make a test where the last argument is a string that contains an expression
but the cursor is not on the expression (so we auto-complete to nothing,
instead of that expression's auto-complete). e.g.
 - `foo "Some argument |cursor|that has ${FOO} here"
  - The cursor isn't on FOO so it shouldn't auto-complete like it is

Do TODO notes

- Make sure that dynamic expressions don't accidentally trigger validtion failure if the expression evaluates into valid input
