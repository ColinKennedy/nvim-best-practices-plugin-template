--- Busted command-line runner
---
--- This page is a slight fork of
--- https://github.com/lunarmodules/busted/blob/master/busted/runner.lua, which
--- unfortunately is unusable because it is too strict for our needs.
---
---@module 'busted.multi_runner'
---

--- @class busted.MultiRunner A unittest suite runner.

--- @class busted.MultiRunnerOptions The settings used to control how the runner executes the tests.

-- TODO: Simplify the code here, later

local path = require("pl.path")
local tablex = require("pl.tablex")
local term = require("term")
local utils = require("busted.utils")
local exit = require("busted.compatibility").exit
local loadstring = require("busted.compatibility").loadstring

--- Execute the test suite.
---
---@param options busted.MultiRunnerOptions The settings to apply to the runner.
---
return function(options)
    local isatty = io.type(io.stdout) == "file" and term.isatty(io.stdout)
    options = tablex.update(require("busted.options"), options or {})
    options.output = options.output or (isatty and "utfTerminal" or "plainTerminal")

    local busted = require("busted.core")()

    local cli = require("busted.modules.cli")(options)
    local filterLoader = require("busted.modules.filter_loader")()
    local helperLoader = require("busted.modules.helper_loader")()
    local outputHandlerLoader = require("busted.modules.output_handler_loader")()

    local luacov = require("busted.modules.luacov")()

    require("busted")(busted)

    local level = 2
    local info = debug.getinfo(level, "Sf")
    local source = info.source
    local fileName = source:sub(1, 1) == "@" and source:sub(2) or nil
    local forceExit = fileName == nil

    -- Parse the cli arguments
    local appName = path.basename(fileName or "busted")
    cli:set_name(appName)
    local cliArgs, err = cli:parse(arg)
    if not cliArgs then
        io.stderr:write(err .. "\n")
        exit(1, forceExit)
    end

    if cliArgs.help then
        io.stdout:write(cliArgs.helpText .. "\n")
        exit(0, forceExit)
    end

    if cliArgs.version then
        -- Return early if asked for the version
        io.stdout:write(busted.version .. "\n")
        exit(0, forceExit)
    end

    -- Load current working directory
    local ok, err = path.chdir(path.normpath(cliArgs.directory))

    if err then
        io.stderr:write(appName .. ": error: " .. err .. "\n")
        exit(1, forceExit)
    end

    -- If coverage arg is passed in, load LuaCovsupport
    if cliArgs.coverage then
        ok, err = luacov(cliArgs["coverage-config-file"])
        if not ok then
            io.stderr:write(appName .. ": error: " .. err .. "\n")
            exit(1, forceExit)
        end
    end

    -- If auto-insulate is disabled, re-register file without insulation
    if not cliArgs["auto-insulate"] then
        busted.register("file", "file", {})
    end

    -- If lazy is enabled, make lazy setup/teardown the default
    if cliArgs.lazy then
        busted.register("setup", "lazy_setup")
        busted.register("teardown", "lazy_teardown")
    end

    -- Add additional package paths based on lpath and cpath cliArgs
    if #cliArgs.lpath > 0 then
        package.path = (cliArgs.lpath .. ";" .. package.path):gsub(";;", ";")
    end

    if #cliArgs.cpath > 0 then
        package.cpath = (cliArgs.cpath .. ";" .. package.cpath):gsub(";;", ";")
    end

    -- Load and execute commands given on the command-line
    if cliArgs.e then
        for _, v in ipairs(cliArgs.e) do
            loadstring(v)()
        end
    end

    -- watch for test errors and failures
    local failures = 0
    local errors = 0
    local quitOnError = not cliArgs["keep-going"]

    busted.subscribe({ "error", "output" }, function(element, _, message)
        io.stderr:write(appName .. ": error: Cannot load output library: " .. element.name .. "\n" .. message .. "\n")

        return nil, true
    end)

    busted.subscribe({ "error", "helper" }, function(element, _, message)
        io.stderr:write(appName .. ": error: Cannot load helper script: " .. element.name .. "\n" .. message .. "\n")

        return nil, true
    end)

    busted.subscribe({ "error" }, function()
        errors = errors + 1
        busted.skipAll = quitOnError

        return nil, true
    end)

    busted.subscribe({ "failure" }, function(element)
        if element.descriptor == "it" then
            failures = failures + 1
        else
            errors = errors + 1
        end

        busted.skipAll = quitOnError

        return nil, true
    end)

    -- Set up randomization options
    busted.sort = cliArgs["sort-tests"]
    busted.randomize = cliArgs["shuffle-tests"]
    busted.randomseed = tonumber(cliArgs.seed) or utils.urandom() or os.time()

    -- Set up output handler to listen to events
    outputHandlerLoader(busted, cliArgs.output, {
        arguments = cliArgs.Xoutput,
        defaultOutput = options.output,
        deferPrint = cliArgs["defer-print"],
        enableSound = cliArgs["enable-sound"],
        language = cliArgs.lang,
        release = options.release,
        root = options.root,
        suppressPending = cliArgs["suppress-pending"],
        verbose = cliArgs.verbose,
    })

    -- Pre-load the LuaJIT 'ffi' module if applicable
    require("busted.luajit")()

    -- Set up helper script, must succeed to even start tests
    if cliArgs.helper and cliArgs.helper ~= "" then
        ok, err = helperLoader(busted, cliArgs.helper, {
            verbose = cliArgs.verbose,
            language = cliArgs.lang,
            arguments = cliArgs.Xhelper,
        })
        if not ok then
            io.stderr:write(
                appName .. ": failed running the specified helper (" .. cliArgs.helper .. "), error: " .. err .. "\n"
            )
            exit(1, forceExit)
        end
    end

    local getFullName = function(name)
        local parent = busted.context.get()
        local names = { name }

        while parent and (parent.name or parent.descriptor) and parent.descriptor ~= "file" do
            table.insert(names, 1, parent.name or parent.descriptor)
            parent = busted.context.parent(parent)
        end

        return table.concat(names, " ")
    end

    if cliArgs["log-success"] then
        local logFile = assert(io.open(cliArgs["log-success"], "a"))
        busted.subscribe({ "test", "end" }, function(_, _, status)
            if status == "success" then
                logFile:write(getFullName() .. "\n")
            end
        end)
    end

    -- Load tag and test filters
    filterLoader(busted, {
        tags = cliArgs.tags,
        excludeTags = cliArgs["exclude-tags"],
        filter = cliArgs.filter,
        name = cliArgs.name,
        filterOut = cliArgs["filter-out"],
        excludeNamesFile = cliArgs["exclude-names-file"],
        list = cliArgs.list,
        nokeepgoing = not cliArgs["keep-going"],
        suppressPending = cliArgs["suppress-pending"],
    })

    if cliArgs.ROOT then
        -- Load test directories/files
        local rootFiles = cliArgs.ROOT
        local patterns = cliArgs.pattern
        local testFileLoader = require("busted.modules.test_file_loader")(busted, cliArgs.loaders)
        testFileLoader(rootFiles, patterns, {
            excludes = cliArgs["exclude-pattern"],
            verbose = cliArgs.verbose,
            recursive = cliArgs["recursive"],
        })
    else
        -- Running standalone, use standalone loader
        local testFileLoader = require("busted.modules.standalone_loader")(busted)
        testFileLoader(info, { verbose = cliArgs.verbose })
    end

    local runs = cliArgs["repeat"]
    local execute = require("busted.execute")(busted)
    execute(runs, {
        seed = cliArgs.seed,
        shuffle = cliArgs["shuffle-files"],
        sort = cliArgs["sort-files"],
    })

    busted.publish({ "exit" })

    if options.standalone or failures > 0 or errors > 0 then
        exit(failures + errors, forceExit)
    end
end
