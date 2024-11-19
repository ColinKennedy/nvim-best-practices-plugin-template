BUSTED_PROFILER_FLAMEGRAPH_VERSION=v1.2.3 BUSTED_PROFILER_FLAMEGRAPH_OUTPUT_PATH=/tmp/directory make profile_using_flamegraph
BUSTED_PROFILER_FLAMEGRAPH_VERSION=v1.2.3 BUSTED_PROFILER_FLAMEGRAPH_OUTPUT_PATH=/tmp/directory nvim -l busted_testout.lua

BUSTED_PROFILER_KEEP_TEMPORARY_FILES=1 BUSTED_PROFILER_FLAMEGRAPH_VERSION=v1.2.3 BUSTED_PROFILER_FLAMEGRAPH_OUTPUT_PATH=/tmp/directory nvim -l busted_testout.lua

BUSTED_PROFILER_KEEP_TEMPORARY_FILES=1 BUSTED_PROFILER_FLAMEGRAPH_VERSION=v1.2.3 BUSTED_PROFILER_FLAMEGRAPH_OUTPUT_PATH=/tmp/directory make profile_using_flamegraph

BUSTED_PROFILER_KEEP_TEMPORARY_FILES=1 BUSTED_PROFILER_FLAMEGRAPH_VERSION=v1.2.3 BUSTED_PROFILER_FLAMEGRAPH_OUTPUT_PATH=/tmp/directory nvim -l busted_testout2.lua

BUSTED_PROFILER_KEEP_TEMPORARY_FILES=1 BUSTED_PROFILER_FLAMEGRAPH_VERSION=v1.2.3 BUSTED_PROFILER_FLAMEGRAPH_OUTPUT_PATH=/tmp/directory nvim -l busted_testout2.lua

LUA_PATH="lua/?.lua;lua/?/init.lua;spec/?.lua;$LUA_PATH" BUSTED_PROFILER_KEEP_TEMPORARY_FILES=1 BUSTED_PROFILER_FLAMEGRAPH_VERSION=v1.2.3 BUSTED_PROFILER_FLAMEGRAPH_OUTPUT_PATH=/tmp/directory nvim -l busted_testout2.lua

eog /tmp/directory/benchmarks/all/median.png

- Do the TODO_profiler.md work
- Do all current branch (add_profiling) TODO notes
    - Can I just use the regular profile.lua module? Do I need the fork?
- Fix the URL to luarocks to show the other location
- Mention the Google "release please" workflow in the README.md
    - Explain releases in the Wiki

- Add documentation on setting up renovate
 - Add details on how to delete renovate (remove the .json file)

## Miscellaneous
- Windows busted support
- Consider adding LuaCov coverage reports. It could be a PR review tool?

```
-c, --[no-]coverage         do code coverage analysis (requires
                            `LuaCov` to be installed) (default: off)
```


## URLChecker Bug
- URLChecker false positive should be fixed

https://github.com/ColinKennedy/nvim-best-practices-plugin-template/actions/runs/11790742700/job/32841671133?pr=20
```
🤔 Uh oh... The following urls did not pass:
❌️ https://github.com/ColinKennedy/nvim-best-practices-plugin-template/compare/v1.3.1...v1.3.2
```

The error occurred because I'm trying to release v1.3.2. So of course the tag
doesn't exist yet.

It's not a big deal but it'd be better if the CI actually ran as expected
instead of "false negative"-ing here.


## Spell Checking
- Add spelling check - https://github.com/ColinKennedy/neovim/actions/runs/11768980943
 - https://github.com/neovim/neovim/blob/master/scripts/gen_help_html.lua
  - Spellcheck (only in docstrings)
  - Check links
  - Anything else
 - https://github.com/neovim/neovim/blob/master/.github/workflows/docs.yml

https://github.com/inkarkat/vim-SpellCheck/blob/master/autoload/SpellCheck/quickfix.vim
https://www.reddit.com/r/neovim/comments/1dhyaxs/how_to_setup_code_spellchecking/
https://github.com/matkrin/telescope-spell-errors.nvim/blob/main/lua/telescope/_extensions/spell_errors.lua
https://www.reddit.com/r/neovim/comments/1f42f25/new_telescope_plugin_extension/
https://www.reddit.com/r/neovim/comments/125whev/dumb_question_how_to_spell_check_only_comments/





Consider adding a secrets scanner
- gitleaks
- truffle-hog
- gitguardian


- Split the cmdparse to its own repository
- rg "the is" and fix the typo
- Need to add a TODO: (you) to the plugin/cursor_text_object.lua file


- Add Windows support for busted
https://github.com/lunarmodules/luasystem/blob/85ad15fbd8c81807a1a662f5b6060641fa3a6357/.github/workflows/build.yml#L94

https://github.com/search?q=%22luarocks%22+%22busted%22+%22windows%22+path%3A.github%2Fworkflows%2F*.yml&type=code


https://github.com/savushkin-r-d/ptusa_main/blob/0f8b5c2a4336d38f703778f627ee097d72e288b1/.github/workflows/cmake.yml#L251

https://github.com/ColinKennedy/nvim-best-practices-plugin-template/actions/runs/11549807547/job/32143528005

- Review https://gitlab.com/HiPhish/nvim-busted-shims
- https://gitlab.com/HiPhish/nvim-busted-shims

- Consider the busted test
 - https://github.com/S1M0N38/base.nvim/blob/main/.github/workflows/run-tests.yml

- Performance Profiling
 - https://github.com/AcademySoftwareFoundation/rez/blob/main/.github/workflows/benchmark.yaml

- Consider changing the link tool with reviewdog
- https://github.com/reviewdog/reviewdog
 - https://github.com/umbrelladocs/action-linkspector?tab=readme-ov-file
 - https://github.com/nvim-neorocks/nvim-best-practices/blob/main/.github/workflows/linkspector.yml



```
https://github.com/ColinKennedy/nvim-best-practices-plugin-template/actions/runs/11529572604/job/32098195391

https://github.com/ColinKennedy/nvim-best-practices-plugin-template/actions/runs/11529572604/job/32098195391

https://github.com/leafo/gh-actions-luarocks

https://github.com/leafo/gh-actions-lua/blob/master/README.md#full-example

https://github.com/leafo/gh-actions-lua

https://github.com/search?q=path%3A.github%2Fworkflows%2F*.yml+msvc-dev-cmd+luarocks&type=code

https://github.com/khvzak/lua-ryaml/blob/de56e4730f8e988b9a3701fe90ee1771553836ab/.github/workflows/main.yml#L76

https://github.com/lvgl/lvgl/blob/d25a6e0e76a6f0e00c63a9091cb0a8974968fd37/.github/workflows/ccpp.yml#L51

https://github.com/ValveSoftware/GameNetworkingSockets/blob/725e273c7442bac7a8bc903c0b210b1c15c34d92/.github/workflows/build.yml#L54

https://raw.githubusercontent.com/lunarmodules/luasocket/1fad1626900a128be724cba9e9c19a6b2fe2bf6b/.github/workflows/build.yml

https://github.com/lunarmodules/luasocket/blob/1fad1626900a128be724cba9e9c19a6b2fe2bf6b/.github/workflows/build.yml#L23

https://gitlab.com/HiPhish/nvim-busted-shims/-/blob/master/nvim?ref_type=heads

https://gitlab.com/HiPhish/nvim-busted-shims
```


Trying to get luarocks on Windows working


```
https://github.com/ColinKennedy/nvim-best-practices-plugin-template/actions/runs/11543956333/job/32128931313

https://productionresultssa19.blob.core.windows.net/actions-results/68169a6d-652f-4131-8489-2ff57a86bc1f/workflow-job-run-b0ef97c8-275e-58ff-f9c8-693782eb3869/logs/job/job-logs.txt?rsct=text%2Fplain&se=2024-10-27T21%3A47%3A22Z&sig=iO0ibYG105HOWjozbPGLdHadmFwnGl86IHjtLb%2FRbOI%3D&ske=2024-10-28T08%3A52%3A56Z&skoid=ca7593d4-ee42-46cd-af88-8b886a2f84eb&sks=b&skt=2024-10-27T20%3A52%3A56Z&sktid=398a6654-997b-47e9-b12b-9515b896b4de&skv=2024-08-04&sp=r&spr=https&sr=b&st=2024-10-27T21%3A37%3A17Z&sv=2024-08-04

https://github.com/ColinKennedy/nvim-best-practices-plugin-template/actions/runs/11543901518/job/32128823939

https://github.com/ColinKennedy/nvim-best-practices-plugin-template/actions/runs/11543823651/job/32128665851

https://github.com/ColinKennedy/nvim-best-practices-plugin-template/actions/runs/11543857623/job/32128734846

https://github.com/ColinKennedy/nvim-best-practices-plugin-template/actions/runs/11543747747/job/32128534526

https://github.com/ColinKennedy/nvim-best-practices-plugin-template/actions/runs/11543747747/job/32128498839

https://github.com/leafo/gh-actions-lua/issues/6

https://github.com/leafo/gh-actions-lua/issues/26

https://github.com/leafo/gh-actions-lua/issues/53

https://github.com/leafo/gh-actions-luarocks/pull/14

https://github.com/nvim-neorocks/rocks-binaries/actions/runs/8168782585/job/22331528480#step:11:1256

https://github.com/nvim-neorocks/rocks-binaries/actions/runs/11540882617

https://github.com/lunarmodules/busted/issues/275
```
