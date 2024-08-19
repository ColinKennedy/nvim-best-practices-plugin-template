--- Symbolic variables to use for all `hello-world say`-related commands.
---
--- @module 'plugin_template._commands.say.constant'
---

return {
    Subcommand = {phrase = "phrase", word = "word"},
    Keyword = {style={lowercase="lowercase", uppercase="uppercase"}}
}
