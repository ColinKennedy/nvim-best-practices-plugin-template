.PHONY: api-documentation download-dependencies llscheck luacheck stylua test

# Git will error if the repository already exists. We ignore the error.
# NOTE: We still print out that we did the clone to the user so that they know.
#
ifeq ($(OS),Windows_NT)
    IGNORE_EXISTING =
else
    IGNORE_EXISTING = 2> /dev/null || true
endif

CONFIGURATION = .luarc.json

download-dependencies:
	git clone git@github.com:Bilal2453/luvit-meta.git .dependencies/luvit-meta $(IGNORE_EXISTING)
	git clone git@github.com:ColinKennedy/mega.cmdparse.git .dependencies/mega.cmdparse $(IGNORE_EXISTING)
	git clone git@github.com:ColinKennedy/mega.logging.git .dependencies/mega.logging $(IGNORE_EXISTING)
	git clone git@github.com:LuaCATS/busted.git .dependencies/busted $(IGNORE_EXISTING)
	git clone git@github.com:LuaCATS/luassert.git .dependencies/luassert $(IGNORE_EXISTING)

api-documentation:
	nvim -u scripts/make_api_documentation/minimal_init.lua -l scripts/make_api_documentation/main.lua

llscheck: download-dependencies
	VIMRUNTIME="`nvim --clean --headless --cmd 'lua io.write(os.getenv("VIMRUNTIME"))' --cmd 'quit'`" llscheck --configpath $(CONFIGURATION) .

luacheck:
	luacheck lua plugin scripts spec

check-stylua:
	stylua lua plugin scripts spec --color always --check

stylua:
	stylua lua plugin scripts spec

test: download-dependencies
	busted .

check-mdformat:
	python -m mdformat --check README.md markdown/manual/docs/index.md

mdformat:
	python -m mdformat README.md markdown/manual/docs/index.md

# IMPORTANT: Make sure to run this first
# ```
# luarocks install busted
# luarocks install luacov
# luarocks install luacov-multiple
# ```
#
coverage-html: download-dependencies
	nvim -u NONE -U NONE -N -i NONE --headless -c "luafile scripts/luacov.lua" -c "quit"
	luacov --reporter multiple.html
