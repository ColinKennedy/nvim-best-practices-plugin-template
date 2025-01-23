--- Read a unprocessed rockspec template and convert it into a real .rockspec file.
---
--- Important:
---     This repository is a hack and is not meant to be used outside of its
---     limited scope. Because of that, the generated .rockspec is "real" in
---     that `luarocks` can call it but its contents is intended to be mostly
---     empty / fake.
---

local OS = require("ltr.os")
local rockspec_ = require("ltr.rockspec")

--- Read `path` file path and get its contents.
---
---@param path string A relative or absolute path to get data from.
---@return string # All data from `path`.
---
local function _get_contents(path)
    local handler = io.open(path, "r")

    if not handler then
        error(string.format('Path "%s" could not be opened.', path))
    end

    local data = handler:read("*a")

    handler:close()

    return data
end

--- Make sure `path` follows `"foo-scm-1.rockspec"`.
---
--- luarocks has specific conventions that you must follow or it cannot read
--- the file so this check is to make sure that the output path will work with
--- luarocks.
---
--- Raises:
---     If `path` will not be able to be read by luarocks.
---
---@param path string? Some relative or absolute path.
---
local function _validate_output(path)
    if not path then
        error('You must provide an output path. e.g. "foo-scm-1.rockspec".', 0)
    end

    local pattern = "(.+)%-([^%-]+)%-([^%-]+)%.rockspec$"

    if string.match(path, pattern) then
        return
    end

    error(string.format('Path "%s" must match "%s".', path), 0)
end

---Find the (GitHub action) user input.
---
--- Raises:
---     If any expected user input was not provided or could not be parsed.
---
---@return string
---    The unprocessed template file path.
---@return string
---    The path where we will write the end .rockspec file to-disk.
---@return boolean
---    If `true`, delete the unprocessed template file path
---    after the end .rockspec is created. If `false, leave the template alone.
---
local function _parse_arguments()
    local rockspec_template = arg[1]

    if not rockspec_template then
        error('You must provide a template. e.g. "template.rockspec".', 0)
    end

    local output_path = arg[2]

    _validate_output(output_path)

    ---@type (string | boolean)?
    local delete_input_after = arg[3]

    if not delete_input_after then
        delete_input_after = false
    elseif delete_input_after == "true" then
        delete_input_after = true
    elseif delete_input_after == "false" then
        delete_input_after = false
    else
        error(
            string.format(
                'WARNING: Unknown delete_input_after "%s" was found. Defaulting to false.',
                delete_input_after
            ),
            0
        )
    end

    ---@cast delete_input_after boolean

    return rockspec_template, output_path, delete_input_after
end

--- Process a template and output a .rockspec file.
local function main()
    local rockspec_template_path, output_path, delete_input_after = _parse_arguments()
    local rockspec_template = _get_contents(rockspec_template_path)

    local package_name = "fake_package"
    local modrev = "scm"
    local specrev = "1"

    local rockspec = rockspec_.generate(package_name, modrev, specrev, rockspec_template, {
        copy_directories = {},
        ref_type = "branch",
        git_server_url = "",
        github_repo = "",
        license = "",
        git_ref = "",
        summary = "",
        detailed_description_lines = {},
        dependencies = {},
        test_dependencies = {},
        labels = {},
        repo_name = "fake_repository",
        github_event_tbl = "",
    })

    print(string.format("The rockspec\n\n```lua\n%s\n```\n\n...was generated successfully", rockspec))

    OS.write_file(output_path, rockspec)

    print(string.format('Expanded "%s" and wrote it to "%s".', rockspec_template_path, output_path))

    if delete_input_after then
        assert(os.remove(rockspec_template_path))
    end
end

main()
