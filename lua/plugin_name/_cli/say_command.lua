local tabler = require("plugin_name._core.tabler")

local M = {}

local _SAY_COMMANDS

-- TODO: Docstrings

-- TODO: Move this to somewhere common late

local function _run_phrase(data)
    print(vim.inspect(data))
end

function M.run_say(data)
    local runner = _SAY_COMMANDS[data.positions[2]]

    local positions = tabler.get_slice(data.positions, 2)
    data = vim.tbl_deep_extend("force", data, { positions = positions })

    runner(data)
end

-- TODO: Replace with API calls
_SAY_COMMANDS = {
    word = _run_phrase,
    phrase = _run_phrase,
}

return M
