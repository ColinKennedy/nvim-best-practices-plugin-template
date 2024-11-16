-- TODO: Add docstring

local function _clear_arg()
    for key, _ in pairs(arg) do
        if key ~= 0 then
            arg[key] = nil
        end
    end
end

local function _keep_arg(caller)
    local original = vim.deepcopy(arg)

    caller()

    for key, value in pairs(original) do
        arg[key] = value
    end
end

local function _run_busted_suite(runner)
    _keep_arg(function()
        _clear_arg()

        arg[1] = "--ignore-lua"
        arg[2] = "--helper=spec/minimal_init.lua"
        arg[3] = "--output=busted.profile_using_flamegraph"

        runner({ standalone=false })
    end)
end

local function main()
    local maximum_tries = 10
    local counter = 10
    local fastest_time = 2^1023

    while true do
        print("running")
        local before = os.clock()

        local runner = require("busted.runner")
        _run_busted_suite(runner)
        -- NOTE: It looks like for some reason busted forces `runner()` to
        -- return an empty table if it is called more than once. Which is
        -- weird. So we have to force-remove the module so we can load it from
        -- scratch again.
        --
        package.loaded["busted.runner"] = nil

        local duration = os.clock() - before

        if duration < fastest_time then
            counter = maximum_tries
            fastest_time = duration
        else
            counter = counter - 1
        end

        if counter == 0 then
            break
        end
    end
end

main()
