## TODO
- Change the logic so that .png generation is skipped unless there are at least 2 artifacts
 - Add a config variable + add it to the action so this is controllable

- Make it so you can run the tool retroactively on older tags (and it still works)
- Make mega.busted real so that I can upload it to luarocks and use it elsewhere
- Allow profliing Neovim startup time (in my personal Neovim configuration)

- github action
 - git checkout another branch (make it if it doesn't exist)
 - merge with the main, default branch
 - run profiler
 - commit the results and push it back


- Also allow on-start-up profiling (so it can be used for regular Neovim configurations)
 - standalone
  - Show startup time with the current environment
 - over time, with releases
  - Make a double-line graph. Show Neovim without the plugin / extension(s) and another line with it


- Do TODO notes
- make a github action that encapsulates everything
- In GitHub workflows, make sure to print out the top 20 slowest, as part of the steps


```
- 🚅 [Speed](docs/speed/timing.png) (TODO FIX THIS LATER)
```
make this link real, later
- make sure all README.md links work


- /home/selecaoone/repositories/personal/.config/nvim/bundle/nvim-best-practices-plugin-template/lua/busted/multi_runner.lua
 - document to users that they can send any busted call to this runner

- Document how to get a flame graph from that output easily

- A GitHub workflow that can keep in sync with main + add more commits
 - on a separate branch
 - A dedicated git branch called profiling
    - It is up to date with main at all times
 - Consider Allowing the summary page in the main branch to exist - but only as a link / reference to the images that are in the other branch
    - e.g. Get the URL to the other branch and copy the data into the main branch. Or something

https://github.com/lunarmodules/busted/blob/94d008108b028817534047b44fdb1f7f7ca0dcc3/busted/runner.lua#L215-L217

https://github.com/AcademySoftwareFoundation/rez/blob/main/.github/scripts/store_benchmark.py



### TODO Later
- Document how the user should create profiles / view flamegraph results to view it

- Add a thing that times the unittests and notifies if the code is much slower
 - maybe make it ignore feat() commits?



- https://github.com/pianohacker/bucket/blob/ef0d5f59ca568feab9fc52da029922b17322593e/profiler.lua#L49
