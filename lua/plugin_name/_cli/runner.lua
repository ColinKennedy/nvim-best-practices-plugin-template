local argparse = require("plugin_name._cli.argparse")

local M = {}

function M.run_hello_world(data)
  local positions, named = argparse.parse_args(data)
  print("Got these arguments")
  print(vim.inspect(positions))
  print(vim.inspect(named))
end

return M
