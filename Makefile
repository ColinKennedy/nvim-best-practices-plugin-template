.PHONY: documentation llscheck luacheck stylua test

api_documentation:
	nvim -l scripts/make_api_documentation.lua

llscheck:
	llscheck --configpath .luarc.json .

luacheck:
	luacheck lua plugin spec

stylua:
	stylua lua plugin spec

test:
	eval $(luarocks path --lua-version 5.1 --bin)
	busted --helper spec/minimal_init.lua .
