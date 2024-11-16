-- TODO: Add docstring

local compatibility = require('busted.compatibility')
local tablex = require 'pl.tablex'
local term = require('term')

local _HELPER = "spec/minimal_init.lua"
local _OUTPUT_HANDLER = "busted.profile_using_flamegraph"


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

local function _run_busted_suite(busted)
    local helperLoader = require("busted.modules.helper_loader")()
    local outputHandlerLoader = require("busted.modules.output_handler_loader")()

    local force_exit = _get_current_file() == nil

    local failures = 0
    local errors = 0
    local quit_on_error = true

    busted.subscribe({ "error", "output" }, function(element, parent, message)
        io.stderr:write("busted: error: Cannot load output library: " .. element.name .. "\n" .. message .. "\n")

        return nil, true
    end)

    busted.subscribe({ "error", "helper" }, function(element, parent, message)
        io.stderr:write("busted: error: Cannot load helper script: " .. element.name .. "\n" .. message .. "\n")

        return nil, true
    end)

    busted.subscribe({ "error" }, function(element, parent, message)
        errors = errors + 1
        busted.skipAll = quit_on_error

        return nil, true
    end)

    busted.subscribe({ "failure" }, function(element, parent, message)
        if element.descriptor == "it" then
            failures = failures + 1
        else
            errors = errors + 1
        end

        busted.skipAll = quit_on_error

        return nil, true
    end)

    local language = "en"

    busted.sort = true

    -- TODO: Add this
    -- outputHandlerLoader(busted, _OUTPUT_HANDLER, {
    --     defaultOutput = _get_default_output(),
    --     deferPrint = false,
    --     enableSound = false,
    --     language = language,
    --     verbose = false,
    -- })

    require("busted.luajit")()

    local ok, message = helperLoader(busted, _HELPER, { verbose = true, language = language })

    if not ok then
        io.stderr:write(
            "busted: failed running the specified helper (" .. helper .. "), error: " .. message .. "\n"
        )
        compatibility.exit(1, force_exit)
    end

    local load_tests = require("busted.modules.test_file_loader")(busted, {"lua"})
    load_tests({"."}, {"_spec"}, { excludes = {}, recursive = true })

    local execute = require("busted.execute")(busted)

    execute(1, { language = language, sort = true })

    if failures > 0 or errors > 0 then
        compatibility.exit(failures + errors, force_exit)
    end
end

local function main()
    local maximum_tries = 10
    local counter = 10
    local fastest_time = 2 ^ 1023

    local busted = require("busted.core")()
    require("busted")(busted)  -- TODO: not sure if this is meant to go here or before each test (in the for-loop)

    while true do
        local before = os.clock()

        _run_busted_suite(busted)

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
