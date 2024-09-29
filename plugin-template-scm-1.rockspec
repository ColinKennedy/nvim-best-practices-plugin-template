rockspec_format = '3.0'
package = 'plugin-template'
version = 'scm-1'

test_dependencies = {
  'busted >= 2.0, < 3.0',
  'lua >= 5.1, < 6.0',
  'nlua >= 0.2, < 1.0',
  'nui.nvim >= 0.2, < 1.0',
}

test = {
  command = "busted --helper spec/minimal_init.lua .",
  type = "command",
}

source = {
  url = 'git://github.com/ColinKennedy/' .. package,
}

build = {
  type = 'builtin',
}
