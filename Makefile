.PHONY: api_documentation flamegraph llscheck luacheck stylua test

# Git will error if the repository already exists. We ignore the error.
# NOTE: We still print out that we did the clone to the user so that they know.
#
ifeq ($(OS),Windows_NT)
    IGNORE_EXISTING = 2> nul
else
    IGNORE_EXISTING = 2> /dev/null || true
endif

clone_git_dependencies:
	git clone git@github.com:ColinKennedy/mega.cmdparse.git .dependencies/mega.cmdparse $(IGNORE_EXISTING)
	git clone git@github.com:LuaCATS/busted.git .dependencies/busted $(IGNORE_EXISTING)
	git clone git@github.com:LuaCATS/luassert.git .dependencies/luassert $(IGNORE_EXISTING)
	git clone git@github.com:Bilal2453/luvit-meta.git .dependencies/luvit-meta $(IGNORE_EXISTING)

api_documentation:
	nvim -u scripts/make_api_documentation/minimal_init.lua -l scripts/make_api_documentation/main.lua

flamegraph:
	nvim -l lua/busted/profiler_runner.lua

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
