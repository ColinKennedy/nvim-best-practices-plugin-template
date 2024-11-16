.PHONY: api_documentation llscheck luacheck stylua test

api_documentation:
	nvim -u scripts/make_api_documentation/minimal_init.lua -l scripts/make_api_documentation/main.lua

llscheck:
	VIMRUNTIME=`nvim -l scripts/print_vimruntime_environment_variable.lua` llscheck --configpath .luarc.json .

luacheck:
	luacheck lua plugin scripts spec

stylua:
	stylua lua plugin scripts spec

test:
	busted --helper spec/minimal_init.lua .

profile_using_flamegraph:
	busted --helper spec/minimal_init.lua --output=busted.profile_using_flamegraph .

profile_using_vim:
	busted --helper spec/minimal_init.lua --output=busted.profile_using_vim .
