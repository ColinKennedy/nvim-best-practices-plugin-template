local argparse = require("plugin_name._cli.argparse")

local M = {}

-- TODO: Add better code here

function M.run_goodnight_moon(data)
  local positions, named = argparse.parse_args(data)
end

function M.run_hello_world(data)
  local positions, named = argparse.parse_args(data)
end

return M
