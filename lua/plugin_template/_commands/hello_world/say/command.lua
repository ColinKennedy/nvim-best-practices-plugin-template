--- Parse `"hello-world say"` from the COMMAND mode and run it.
---
--- @module 'plugin_template._commands.hello_world.say.command'
---

local runner = require("plugin_template._commands.hello_world.say.runner")

local M = {}

-- TODO: Add docstrings

--- Get `hello-world say phrase` namespace details and run it.
function M.run_say_phrase(namespace)
    runner.run_say_phrase(
        namespace.phrases, namespace["repeat"], namespace.style
    )
end

--- Get `hello-world say word` namespace details and run it.
function M.run_say_word(namespace)
    runner.run_say_word(
        namespace.word, namespace["repeat"], namespace.style
    )
end

return M
