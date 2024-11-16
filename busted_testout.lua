-- TODO: Add docstring

local compatibility = require('busted.compatibility')
local tablex = require 'pl.tablex'
local term = require('term')

local _HELPER = "spec/minimal_init.lua"
local _LANGUAGE = "en"
local _LPATH_EXTENSIONS = 'lua/?.lua;lua/?/init.lua;spec/?.lua'
local _OUTPUT_HANDLER = "busted.profile_using_flamegraph"

-- TODO: Finish docstring
---@class _CumulativeRunnerState
---@field errors number
---@field failures number

local function _get_current_file()
    local level = 2
    local info = debug.getinfo(level, "Sf")
    local source = info.source

    return source:sub(1, 1) == "@" and source:sub(2) or nil
end

local function _get_default_output()
    local isatty = io.type(io.stdout) == 'file' and term.isatty(io.stdout)
    local options = tablex.update(require 'busted.options', options or {})

    return options.output or (isatty and 'utfTerminal' or 'plainTerminal')
end

local function _initialize_busted(busted, state, force_exit)
    require("busted")(busted)  -- TODO: not sure if this is meant to go here or before each test (in the for-loop)

    -- TODO: I'm pretty sure we want to skip on-error. But for now disable it
    -- local quit_on_error = true

    busted.subscribe({ "error", "output" }, function(element, parent, message)
        io.stderr:write("busted: error: Cannot load output library: " .. element.name .. "\n" .. message .. "\n")

        return nil, true
    end)

    busted.subscribe({ "error", "helper" }, function(element, parent, message)
        io.stderr:write("busted: error: Cannot load helper script: " .. element.name .. "\n" .. message .. "\n")

        return nil, true
    end)

    busted.subscribe({ "error" }, function(element, parent, message)
        state.errors = state.errors + 1
        busted.skipAll = quit_on_error

        return nil, true
    end)

    busted.subscribe({ "failure" }, function(element, parent, message)
        if element.descriptor == "it" then
            state.failures = state.failures + 1
        else
            state.errors = state.errors + 1
        end

        busted.skipAll = quit_on_error

        return nil, true
    end)

    busted.sort = true

    local output_handler_loader = require("busted.modules.output_handler_loader")()
    output_handler_loader(busted, _OUTPUT_HANDLER, {
        defaultOutput = _get_default_output(),
        deferPrint = true,
        enableSound = false,
        language = _LANGUAGE,
        verbose = false,
    })

    require("busted.luajit")()

    local helper_loader = require("busted.modules.helper_loader")()
    local ok, message = helper_loader(busted, _HELPER, { verbose = true, language = _LANGUAGE })

    if not ok then
        io.stderr:write(
            "busted: failed running the specified helper (" .. helper .. "), error: " .. message .. "\n"
        )
        compatibility.exit(1, force_exit)
    end

    package.path = _LPATH_EXTENSIONS .. ';' .. package.path

    local load_tests = require("busted.modules.test_file_loader")(busted, {"lua"})
    load_tests({"."}, {"_spec"}, { excludes = {}, recursive = true })
end

local function _run_busted_suite(busted, state, force_exit)
    local execute = require("busted.execute")(busted)

    execute(1, { language = _LANGUAGE, sort = true })

    -- TODO: Not sure if we need this. Probably we do.
    -- if state.failures > 0 or state.errors > 0 then
    --     compatibility.exit(state.failures + state.errors, force_exit)
    -- end
end

local function main()
    local maximum_tries = 10
    local counter = 10
    local fastest_time = 2 ^ 1023

    local force_exit = _get_current_file() == nil

    ---@type _CumulativeRunnerState
    local state = {errors = 0, failures = 0}
    local busted = require("busted.core")()
    _initialize_busted(busted, state, force_exit)

    while true do
        local before = os.clock()

        _run_busted_suite(busted, state, force_exit)

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

    busted.publish({ "exit" })
end

main()
