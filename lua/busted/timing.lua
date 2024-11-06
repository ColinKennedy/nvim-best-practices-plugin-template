local json = require("dkjson")


return function(options)
    local repeated_suite = '\nRepeating all tests (run %u of %u) . . .\n\n'

    handler.suiteStart = function(suite, count, total, randomseed)
        if total > 1 then
            io.write(string.format(repeated_suite, count, total))
        end
    end

    local busted = require("busted")
    local handler = require("busted.outputHandlers.base")()

    handler.suiteEnd = function()
        local error_info = {
            pendings = handler.pendings,
            successes = handler.successes,
            failures = handler.failures,
            errors = handler.errors,
            duration = handler.getDuration(),
        }
        local ok, result = pcall(json.encode, error_info)

        if ok then
            io_write(result)
        else
            io_write("Failed to encode test results to json: " .. result)
        end

        io_write("\n")
        io_flush()

        return nil, true
    end

    handler.suiteStart = function(suite, count, total, randomseed)

    busted.subscribe({ "suite", "end" }, handler.suiteEnd)

    return handler
end
