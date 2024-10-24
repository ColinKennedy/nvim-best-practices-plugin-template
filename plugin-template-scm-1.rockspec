rockspec_format = '3.0'
package = 'plugin-template'
version = 'scm-1'

test_dependencies = {
    'busted >= 2.0, < 3.0',
    'lua >= 5.1, < 6.0',
    'nlua >= 0.2, < 1.0',
    'nui.nvim >= 0.2, < 1.0',
}

-- Reference: https://github.com/luarocks/luarocks/wiki/test#test-types
test = {
    type = "busted",
    flags = {"--helper", "spec/minimal_init.lua"},
}

source = {
    url = 'git://github.com/ColinKennedy/' .. package,
}

build = {
    type = 'builtin',
}
