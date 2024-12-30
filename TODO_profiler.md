## TODO
- Do TODO notes
- make a github action that encapsulates everything

- /home/selecaoone/repositories/personal/.config/nvim/bundle/nvim-best-practices-plugin-template/lua/busted/multi_runner.lua
 - document to users that they can send any busted call to this runner

- Document all of the environment variables
BUSTED_PROFILER_FLAMEGRAPH_OUTPUT_PATH
BUSTED_PROFILER_FLAMEGRAPH_VERSION
BUSTED_PROFILER_KEEP_OLD_TAG_DIRECTORIES
BUSTED_PROFILER_KEEP_TEMPORARY_FILES
BUSTED_PROFILER_MAXIMUM_TRIES
BUSTED_PROFILER_TABLE_STYLE
BUSTED_PROFILER_TAGGED_DIRECTORIES
BUSTED_PROFILER_TIMING_THRESHOLD

- Document how to get a flame graph from that output easily

- Allow the timing output to be a GitHub-style table

- A GitHub workflow that can keep in sync with main + add more commits
 - on a separate branch
 - A dedicated git branch called profiling
    - It is up to date with main at all times
 - Consider Allowing the summary page in the main branch to exist - but only as a link / reference to the images that are in the other branch
    - e.g. Get the URL to the other branch and copy the data into the main branch. Or something

https://github.com/lunarmodules/busted/blob/94d008108b028817534047b44fdb1f7f7ca0dcc3/busted/runner.lua#L215-L217

- TODO: IMPORTANT: @colin-k profile.nvim changes
 - pid
 - tid
 - Added `events` to profile.export
 - Any other changes

https://github.com/AcademySoftwareFoundation/rez/blob/main/.github/scripts/store_benchmark.py

- It should output this:


            - by_release/
                - {UUID}-test_name_with_invalid_characters_replaced/ (generate a UUID for each busted test)
                    - (Use md5.lua to generate the UUID)
                    - README.md
                        - Explain the contents of the directory
                        - The full test name listed here
                        - Profile summary table (slowest stuff listed at the top)
                    - flamegraph.json
                    - profile.json - total time, self time, etc information here
                - README.md
                    - Explain the contents of the directory
                - IMPORTANT: Needs to delete deprecated tests. e.g. compare the
                  generated UUIDs with the folder. Any folder name that isn't
                  found mustve been removed. So it gets deleted. like that


## Profiling
- Profiling
  - write results to a separate branch on each PR/release
   - https://github.com/orgs/community/discussions/24567
    - On PR, warn over a certain threshold
    - On release, write the branch
    - https://github.com/AcademySoftwareFoundation/rez/blob/main/metrics/benchmarking/RESULTS.md
  - Add "self-time" support


### TODO Later
Find a way to not need to inline md5.lua (get it from luarocks, instead)

- Create a make command that creates the flame graph to a file path (have a default path if not provided)

- Document how the user should create profiles / view flamegraph results to view it

- On PR, make a GitHub workflow that errors if a threshold is met (10%)

- In GitHub workflows, make sure to print out the top 20 slowest, as part of the steps

- Add a thing that times the unittests and notifies if the code is much slower
 - maybe make it ignore feat() commits?



- https://github.com/pianohacker/bucket/blob/ef0d5f59ca568feab9fc52da029922b17322593e/profiler.lua#L49
