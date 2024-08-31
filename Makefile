.PHONY: luacheck stylua test

luacheck:
	luacheck lua plugin spec

test:
	eval $(luarocks path --lua-version 5.1 --bin)
	busted --helper spec/minimal_init.lua .
