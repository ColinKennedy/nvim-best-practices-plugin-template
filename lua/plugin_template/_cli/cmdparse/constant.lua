--- Meaningful global variables to reuse across modules.
---
---@module 'plugin_template._cli.cmdparse.constant'
---

local M = {}

---@enum cmdparse.ActionOption
M.Action = { count = "count", store_false = "store_false", store_true = "store_true" }

---@enum cmdparse.ChoiceContext
---    Extra information provided to `cmdparse.Parameter.choices()` when
---    resolving for allowed values.
---
---    auto_completing = "Getting the next auto-completion suggestion(s), if any".
---    error_message = "An error occurred and we want to give the user a list of possible choices".
---    help_message = "The user wrote --help so we need to get choices to display for that".
---    parameter_names = "The (initial) auto-complete options. Show be the full list of possibilities".
---    parsing = "Evaluating the arguments".
---    position_matching = "Trying to match a positional argument".
---    value_matching = "Getting the value that follows a flag or named argument".
---
M.ChoiceContext = {
    auto_completing = "auto_completing",
    error_message = "error_message",
    help_message = "help_message",
    parameter_names = "parameter_names",
    parsing = "parsing",
    position_matching = "position_matching",
    value_matching = "value_matching",
}

---@enum cmdparse.Counter
M.Counter = {
    one_or_more = "+",
    zero_or_more = "*",
}

return M
