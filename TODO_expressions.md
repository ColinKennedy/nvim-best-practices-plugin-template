- Allow evaluation of vimscript / shell, e.g.
    - important, make sure spaces are not skipped (e.g. `python (foo)` is not an expression but `python(foo)` is)
    - vimscript :()
    - shell $()
    - python Python()
    - Lua Lua()
    - Shell variables - ${}

    - When expanded, use their data directly. OR if it's around quotes, use it as quotes
        - Escape expressions inside of single quotes. But not double quotes
    - Add expression handler API
    - Make sure expression arguments run even if the closing ) is not found!
    - Make sure users can escape expression-ending text

- Make a test where the last argument is a string that contains an expression
but the cursor is not on the expression (so we auto-complete to nothing,
instead of that expression's auto-complete)

Do TODO notes
