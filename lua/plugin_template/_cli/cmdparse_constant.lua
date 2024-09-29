-- TODO: Finish
local M = {}

---@enum cmdparse.ChoiceContext
---    Extra information provided to `cmdparse.Parameter.choices()` when
---    resolving for allowed values.
M.ChoiceContext = {
    auto_completing = "auto_completing",
    error_message = "error_message",
    help_message = "help_message",
    parameter_names = "parameter_names",
    position_matching = "position_matching",
    value_matching = "value_matching",
}

M.Counter = {
    one_or_more = "+",
    zero_or_more = "*",
}

return M
