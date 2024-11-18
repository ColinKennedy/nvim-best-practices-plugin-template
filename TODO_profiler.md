- Create a CPU cycle counter. Incorporate it


## TODO
- A GitHub workflow that can keep in sync with main + add more commits
 - on a separate branch

https://github.com/lunarmodules/busted/blob/94d008108b028817534047b44fdb1f7f7ca0dcc3/busted/runner.lua#L215-L217

https://github.com/AcademySoftwareFoundation/rez/blob/main/.github/scripts/store_benchmark.py

- It should output this:
    - A dedicated git branch called profiling
        - It is up to date with main at all times
    - Consider Allowing the summary page in the main branch to exist - but only as a link / reference to the images that are in the other branch
        - e.g. Get the URL to the other branch and copy the data into the main branch. Or something
    - benchmarks/
        - busted/
            - all/
                - artifacts/
                    - {YYYY_MM_DD-VERSION_TAG}/
                        - Contains their own README.md + summary.json
                - README.md
                    - Show the graph of the output, across versions
                    - A table summary of the timing
                - flamegraph.json
                - profile.json - total time, self time, etc information here
                - timing.png
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

    - A summary view of all past releases
    - Detailed information


- Need to find a way to run unittests as "get the best time of 10 consecutive runs"
    - Test the runs-remaining to 10
    - run a suite
        - If it's faster than the previous run, reset the runs-remaining to 10
        - If slower, decrement the runs-remaining by 1
    - If runs-remaining is 0, that's the final statistics
    - We need this to be able to compute timing while the CPU cache is hot
    - Make this above behavior configurable. e.g. `testing_method = "consecutive-10"` vs `testing_method = "normal"`


## Profiling
- Profiling
 - flamegraph
 - timing
  - write results to a separate branch on each PR/release
   - https://github.com/orgs/community/discussions/24567
    - On PR, warn over a certain threshold
    - On release, write the branch
    - https://github.com/AcademySoftwareFoundation/rez/blob/main/metrics/benchmarking/RESULTS.md
  - Add "self-time" support


### TODO Later
Find a way to not need to inline md5.lua (get it from luarocks, instead)

- Create a GitHub workflow that genberate
- Create a make command that creates the flame graph to a file path (have a default path if not provided)


- Ask busted maintainers how to get a name for a test if it is in a nested describe block


- Create flame graph
    - Document how the user should to view it

- Show timing / graph output of past runs
    - Creates per-file JSON information
    - Creates a graphviz showing the slowest tests, or something

    - Create a GitHub workflow runs on-release
    - On PR, make a GitHub workflow that errors if a threshold is met (10%)

- In GitHub workflows, make sure to print out statistics as part of the steps


https://github.com/hishamhm/busted-htest/blob/master/src/busted/outputHandlers/htest.lua
https://github.com/stevearc/profile.nvim/blob/master/lua/profile/instrument.lua


- Add a "whole suite" profiler option
 - Document how to get a flame graph from that output easily
 - Maybe also print to the terminal so that users in GitHub actions can read it in the output logs
- Add a thing that times the unittests and notifies if the code is much slower
 - maybe make it ignore feat() commits?



- https://github.com/pianohacker/bucket/blob/ef0d5f59ca568feab9fc52da029922b17322593e/profiler.lua#L49
