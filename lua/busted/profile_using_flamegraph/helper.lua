--- The module that handles writing graph and profile and timing data to-disk.
---
---@module 'busted.profile_using_flamegraph.helper'
---

local instrument = require("profile.instrument")
local numeric = require("busted.profile_using_flamegraph.numeric")
local timing = require("busted.profile_using_flamegraph.timing")
local vlog = require("plugin_template._vendors.vlog")

---@class _GraphArtifact Summary data about a whole suite of profiler data.
---@field hardware _Hardware All computer platform details.
---@field versions _Versions All software / hardware metadata that generated `statistics`.
---@field statistics _Statistics Summary data about a whole suite of profiler data.

---@class _GnuplotData The data that we need to generate a graph, using gnuplot.
---@field data_getter fun(artifact: _GraphArtifact): number Grab the value to plot on the graph.
---@field data_path string The .dat file used to read x/y values for the graph.
---@field image_path string The output path where the .png graph will be written to.
---@field script_data string Gnuplot requires a script to generate the graph. This is the script's contents.
---@field script_path string The path on-disk where `script_data` is written to.

---@class _Hardware All computer platform details.
---@field cpu string The name of the CPU that was used when the profiler ran.
---@field platform string The architecture + OS that was used when the profiler ran.

---@class _NeovimFullVersion The output of Neovim's built-in `vim.version()` function.
---@field major number The breaking-change indicator.
---@field minor number The feature indicator.
---@field patch number The bug / fix indicator.

---@class _NeovimSimplifiedVersion A simple major, minor, patch trio.
---@field [1] number The major version.
---@field [2] number The minor version.
---@field [3] number The patch version.

---@class _ProfileEvent A single, recorded profile event.
---@field cat string The category of the profiler event. e.g. `"function"`, `"test"`, etc.
---@field dur number The length of CPU time needed to complete the event.
---@field name string The function call, file path, or other ID.
---@field tid number The thread index number.
---@field ts number The start CPU time.

---@class _Statistics Summary data about a whole suite of profiler data.
---@field mean number (1 + 2 + 3 + ... n) / count
---@field median number The exact middle value of all profile durations.
---@field standard_deviation number The amount of variation in the duration values.
---@field total number The total number of CPU time recorded over the profile.

---@class _Versions
---    All software / hardware metadata that generated `statistics`.
---@field lua string
---    The Lua version that was included with Neovim.
---@field neovim _NeovimFullVersion
---    The user's Neovim version that was used to make the profile results.
---@field release string
---    The version / release tag. e.g. `"v1.2.3"`.
---@field uv number
---    The libuv version that was included with Neovim.

local _LOGGER = vlog.get_logger("busted.profile_using_flamegraph.helper")
local _P = {}
local M = {}

-- NOTE: The X-axis gets crowded if you include too many points so we cap it
-- before it can get to that point
--
local _DEFAULT_MAXIMUM_ARTIFACTS = 35

local _FLAMEGRAPH_FILE_NAME = "flamegraph.json"
local _PROFILE_FILE_NAME = "profile.json"
local _TIMING_FILE_NAME = "timing.txt"

local _MEAN_SCRIPT_TEMPLATE = [[
set xlabel "Release"
set ylabel "Nanoseconds (lower is better)"
set xtics rotate
set term png
set output '%s'
plot "%s" using 2:xtic(1) title 'Mean' with lines linetype 1 linewidth 3
]]

local _MEDIAN_SCRIPT_TEMPLATE = [[
set xlabel "Release"
set ylabel "Nanoseconds (lower is better)"
set xtics rotate
set term png
set output '%s'
plot "%s" using 2:xtic(1) title 'Median' with lines linetype 1 linewidth 3
]]

local _STD_SCRIPT_TEMPLATE = [[
set xlabel "Release"
set ylabel "(lower is better)"
set terminal pngcairo enhanced font 'Arial,12' linewidth 2
set xtics rotate
set term png
set output '%s'
plot "%s" using 2:xtic(1) title 'Standard Deviation' with lines linetype 1 linewidth 3
]]

---@diagnostic disable-next-line: undefined-field
local _PROCESSOR = vim.uv.cpu_info()[1].model

local unpack = table.unpack or unpack

--- Check if `release` is a greater version number than everything in `root`.
---
--- Most of the time this function returns `true`. But if a user is
--- back-patching a version this might return `false`.
---
---@param release number[] A major / minor / patch. e.g. "v1.2.3" would be `{1, 2, 3}`.
---@param root string The directory on-disk where past releases live.
---@return boolean # If `release` is an earlier release number, return `false`.
---
function _P.is_latest_version(release, root)
    for _, directory in ipairs(_P.get_directories(root)) do
        local full_name = vim.fs.basename(directory)
        local version = _P.get_version_from_directory_name(full_name)

        if _P.compare_number_arrays(version, release) == 1 then
            return false
        end
    end

    return true
end

--- Check if `version` is not meant to be directly used to users.
---
---@param version string A full version tag, e.g. `"v1.2.3"`.
---@return boolean # If `"v1.2.3"` return `true`. If `"v4.5.6-beta.1"`, return `false`.
---
function _P.is_stable_release(version)
    for _, word in ipairs({ "-alpha", "-beta", "-rc" }) do
        if string.match(version, word) then
            return false
        end
    end

    return true
end

--- Find all sub-directories starting at `root`.
---
--- Raises:
---     If `root` could not be read.
---
---@param root string The parent directory on-disk to search within.
---@return string[] # All found sub-directories, if any.
---
function _P.get_directories(root)
    local handler = vim.uv.fs_opendir(root)

    if not handler then
        error(string.format('Unable to list "%s" directory.', root), 0)
    end

    ---@type string[]
    local output = {}

    while true do
        local entry = vim.uv.fs_readdir(handler)

        if not entry then
            break
        end

        if entry.type == "directory" then
            table.insert(output, entry.name)
        end
    end

    vim.uv.fs_closedir(handler)

    return output
end

--- Read `"/path/to/2024_08_23-11_03_01-v1.2.3/foo.bar"` for the date + time data.
---
--- If we couldn't find an expected set of date
---
---@param text string The absolute path to the date + time directory.
---@return number[] # All of the date information.
---
function _P.get_directory_name_data(text)
    local output = {}

    for number_text in string.gmatch(text, "%d+") do
        table.insert(output, tonumber(number_text))
    end

    if #output < 9 then
        error(string.format('Text "%s" did not match "vMAJOR.MINOR.PATCH-YYYY_MM_DD-HH_MM_SS" pattern.', text), 0)
    end

    return output
end

--- Read all past profile / timing results into a single array.
---
--- Raises:
---     If a found results file cannot be read from JSON.
---
---     Or if the given `maximum` is invalid.
---
---@param root string
---    An absolute path to the direct-parent directory. e.g. `".../benchmarks/all/artifacts".
---@param maximum number
---    The number of artifacts to read. If not provided, read all of them.
---@return _GraphArtifact[]
---    All found records so far, if any.
---
function _P.get_graph_artifacts(root, maximum)
    ---@type _GraphArtifact[]
    local output = {}

    local template = vim.fs.joinpath(root, "*", _PROFILE_FILE_NAME)

    local all_paths = _P.get_sorted_datetime_paths(vim.fn.glob(template, false, true))
    local count = #all_paths

    _LOGGER:fmt_debug('Writing "%s" artifacts.', count)
    local paths = _P.get_slice(all_paths, math.max(count - maximum + 1, 0), count)

    for index, path in ipairs(paths) do
        _LOGGER:fmt_debug('Reading "%s" artifact.', path)
        local file = io.open(path, "r")

        if not file then
            error(string.format('Path "%s" could not be opened.', path), 0)
        end

        local data = file:read("*a")

        local success, result = pcall(vim.fn.json_decode, data)

        if not success then
            error(string.format('Path "%s" could not be read as JSON.', path), 0)
        end

        table.insert(output, result)

        if index >= maximum then
            _LOGGER:fmt_info('We have reached the "%s" maximum value. All other artifacts will be ignored.', maximum)

            return output
        end
    end

    return output
end

--- Find the most up-to-date Neovim version, if possible.
---
---@param artifacts _GraphArtifact[]
---    All past profiling / timing records to make a graph.
---@return _NeovimSimplifiedVersion?
---    The found version, if any. Only stable versions are allowed. Neovim
---    nightly / prerelease versions are not considered when finding the latest
---    Neovim version.
---
function _P.get_latest_neovim_version(artifacts)
    ---@type _NeovimSimplifiedVersion?
    local output

    for _, artifact in ipairs(artifacts) do
        local version = artifact.versions.neovim

        --     -- TODO: Add this if-statement in, later. But remove it for now because I do use Neovim nightly.
        --     -- if not version.prerelease then  -- version.prerelease indicates a nightly build
        --     --     -- NOTE: We ignore nightly versions because those could cause
        --     --     -- issues during profiling. Instead we favor stable, known
        --     --     -- major.minor.patch versions (like here)
        --     --     --
        --     --     local simplified_version = {version.major, version.minor, version.patch}
        --     --
        --     --     if not output or _P.compare_number_arrays(simplified_version, output) == 1 then
        --     --         output = simplified_version
        --     --     end
        --     -- end

        -- NOTE: We ignore nightly versions because those could cause
        -- issues during profiling. Instead we favor stable, known
        -- major.minor.patch versions (like here)
        --
        local simplified_version = _P.get_simple_version(version)

        if not output or _P.compare_number_arrays(simplified_version, output) == 1 then
            _LOGGER:fmt_info('Found later "%s" Neovim version.', simplified_version)
            output = simplified_version
        end
    end

    return output
end

--- Search `events` for the last event that contains CPU time data.
---
--- Raises:
---     If `events` has no CPU time data.
---
---@param events _ProfileEvent[]
---    All of the profiler event data to consider. If no events are given, we
---    will use the global profiler's events instead.
---@return _ProfileEvent
---    The found, latest event.
---
function _P.get_latest_timed_event(events)
    for index = #events, 1, -1 do
        local event = events[index]

        if event.ts and event.dur then
            return event
        end
    end

    error("Unable to find a latest event.", 0)
end

--- Summarize all of `events` (get the mean, median, etc).
---
--- Raises:
---     If `events` is empty.
---
---@param events _ProfileEvent[]
---    All of the profiler event data to consider. If no events are given, we
---    will use the global profiler's events instead.
---@return _Statistics
---    Summary data about a whole suite of profiler data.
---
function _P.get_profile_statistics(events)
    if vim.tbl_isempty(events) then
        error("Events cannot be empty.")
    end

    ---@type number[]
    local durations = {}
    local sum = 0

    for _, event in ipairs(events) do
        if event.cat == "test" then
            local duration = event.dur
            table.insert(durations, duration)
            sum = sum + duration
        end
    end

    local last_event = _P.get_latest_timed_event(events)

    return {
        median = numeric.get_median(durations),
        mean = sum / #durations,
        total = last_event.ts + last_event.dur,
        standard_deviation = _P.get_standard_deviation(durations),
    }
end

--- Strip unnecessary information from `version`.
---
---@param version _NeovimFullVersion The full `vim.version()` output.
---@return _NeovimSimplifiedVersion # Just the major.minor.patch values.
---
function _P.get_simple_version(version)
    return { version.major, version.minor, version.patch }
end

--- Get a sub-section copy of `table_` as a new table.
---
---@param table_ table<any, any>
---    A list / array / dictionary / sequence to copy + reduce.
---@param first? number
---    The start index to use. This value is **inclusive** (the given index
---    will be returned). Uses `table_`'s first index if not provided.
---@param last? number
---    The end index to use. This value is **inclusive** (the given index will
---    be returned). Uses every index to the end of `table_`' if not provided.
---@param step? number
---    The step size between elements in the slice. Defaults to 1 if not provided.
---@return table<any, any>
---    The subset of `table_`.
---
function _P.get_slice(table_, first, last, step)
    local sliced = {}

    for i = first or 1, last or #table_, step or 1 do
        sliced[#sliced + 1] = table_[i]
    end

    return sliced
end

--- Sort all file-paths on-disk based on their date + time data.
---
--- We assume that these paths follow a format similar to
--- `"/path/to/2024_08_23-11_03_01/foo.bar"`.
---
---@param paths string[] All of the absolute paths on-disk to sort.
---@return string[] # All sorted paths, in ascending order.
---
function _P.get_sorted_datetime_paths(paths)
    return vim.fn.sort(paths, function(left, right)
        if left == right then
            return 0
        end

        return _P.compare_number_arrays(
            _P.get_directory_name_data(vim.fs.dirname(left)),
            _P.get_directory_name_data(vim.fs.dirname(right))
        )
    end)
end

--- Measure the variation in `values`.
---
---@param values number[] All of the values to consider (does not need to be sorted).
---@param mean number? The average value from `values`.
---@return number # The computed standard deviation value.
---
function _P.get_standard_deviation(values, mean)
    local count = #values

    if not mean then
        local sum = 0

        for _, value in ipairs(values) do
            sum = sum + value
        end

        mean = sum / count
    end

    local squared_diff_sum = 0

    for _, value in ipairs(values) do
        squared_diff_sum = squared_diff_sum + (value - mean) ^ 2
    end

    local variance = squared_diff_sum / count

    return math.sqrt(variance)
end

---@return number? # The number of (slowest function) entries to write in the output.
function _P.get_timing_threshold()
    -- TODO: Document this env var. Actually document all env vars
    local text = os.getenv("TIMING_THRESHOLD")

    if not text then
        return nil
    end

    local value = tonumber(text)

    if not value or math.floor(value) ~= value then
        error(string.format('Invalid timing threshold. Got "%s" expected an integer.', text), 0)
    end

    return value
end

--- Get version major / minor / patch details from a `version` text.
---
---@param version string Any version text. e.g. `"v1.2.3"`.
---@return number[] # All found version details.
---
function _P.get_version_numbers(version)
    local output = {}

    for value in version:gmatch("%d+") do
        table.insert(output, value)
    end

    return output
end

--- Make `version` into something more human-readable.
---
--- We assume `version` is not a nightly version.
---
---@param version _NeovimFullVersion The unabridged version data about Neovim.
---@return string # A simplified version name, e.g. `"v0.11.0"`.
---
function _P.get_version_text(version)
    return string.format("v%s.%s.%s", unpack(_P.get_simple_version(version)))
end

--- Check if `left` should be sorted before `right`.
---
--- This function follows the expected outputs of Vim's built-in sort function.
--- See the "{how}" section within `:help sort()` for details.
---
---@param left number[]
---    All of the numbers to compare.
---@param right number[]
---    All of the numbers to compare. We expect this value to come to the right.
---@return number
---    A number that indicates the sorting position. 0 == `left` comes neither
---    before or after `right`. 1 == `left` comes after `right`. -1 == `left`
---    comes before `right`.
---
function _P.compare_number_arrays(left, right)
    local left_count = #left
    local right_count = #right

    for index = 1, math.min(left_count, right_count) do
        if left[index] < right[index] then
            return -1
        elseif left[index] > right[index] then
            return 1
        end
    end

    if left_count < right_count then
        return -1 -- left is smaller because it has fewer elements
    elseif left_count > right_count then
        return 1 -- left is greater because it has more elements
    end

    return 0
end

--- Copy `source` file on-disk to the `destination` directory.
---
--- The copied file has the same file name as `source`.
---
--- Raises:
---     If `source` or `destination` could not be read / written.
---
---@param source string Some file to copy. e.g. `"/foo/bar.txt".
---@param destination string A directory to copy into. e.g. `"/fizz"`.
---
function _P.copy_file_to_directory(source, destination)
    _LOGGER:fmt_info('Copying "%s" source to "%s" destination.', source, destination)

    local source_file = io.open(source, "r")

    if not source_file then
        error(string.format('Cannot open "%s" file.', source), 0)
    end

    local data = source_file:read("*a")

    source_file:close()

    local destination_file = io.open(vim.fs.joinpath(destination, vim.fn.fnamemodify(source, ":t")), "w")

    if not destination_file then
        error(string.format('Cannot open "%s" file.', destination), 0)
    end

    destination_file:write(data)
    destination_file:close()
end

--- Delete the temporary files from `graphs`.
---
---@param graphs _GnuplotData[] All of the graphs that were written to-disk.
---@param attributes string[] All of the attributes to delete from the `graphs`.
---
function _P.delete_gnuplot_paths(graphs, attributes)
    for _, data in ipairs(graphs) do
        for _, name in ipairs(attributes) do
            local path = data[name]

            if path and vim.fn.filereadable(path) == 1 then
                os.remove(path)
            end
        end
    end
end

--- Create the parent directory that will contain `path`.
---
---@param path string
---    An absolute path to a file / symlink. It's expected that `path` does not
---    already exist on disk and probably neither does its parent directory.
---
function _P.make_parent_directory(path)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
end

--- Make sure `version` is an expected semantic version convention.
---
--- Raises:
---     If `version` isn't a valid convention.
---
---@param version string A release / version tag. e.g. `"v1.2.3"`.
---
function _P.validate_release(version)
    local pattern = "^v%d+%.%d+%.%d+$"

    if not string.match(version, pattern) then
        error(string.format('Version "%s" is invalid. Expected Semantic Versioning. See semver.org.', version), 0)
    end
end

--- Write `data` to `path` on-disk.
---
--- Raises:
---     If we cannot write to `path`.
---
---@param data string The blob of text to put into `path`.
---@param path string An absolute path on-disk where `data` will be written to.
---
function _P.write_data_to_file(data, path)
    local file = io.open(path, "w")

    if not file then
        error(string.format('Path "%s" is not writeable.', path), 0)
    end

    file:write(data)

    file:close()
end

--- Export `profile` to `path` as a new profiler flamegraph.
---
---@param profiler Profiler The object used to record function call times.
---@param path string An absolute path to a flamegraph.json to create.
---
function _P.write_flamegraph(profiler, path)
    _LOGGER:fmt_info('Writing flamegraph to "%s" path.', path)
    _P.make_parent_directory(path)

    profiler.export(path)
end

--- Create the gnuplot line-graphs.
---
--- Raises:
---     If we cannot write the graphs (because of missing data, usually).
---
---@param artifacts _GraphArtifact[] All past profiling / timing records to make a graph.
---@param graphs _GnuplotData[] The graph data / images to write to-disk.
---
function _P.write_gnuplot_images(artifacts, graphs)
    -- NOTE: Since timings can vary drastically between Neovim / Lua
    -- versions we don't want to pollute the timing information. We could
    -- create graphs for every permutation but really, most people probably
    -- only care about the latest version. So let's only graph that.
    --
    local neovim_version = _P.get_latest_neovim_version(artifacts)

    if not neovim_version then
        error('Cannot write gnuplot graphs. A "latest Neovim version" could not be found.', 0)
    end

    for _, gnuplot in ipairs(graphs) do
        _P.write_data_to_file(gnuplot.script_data, gnuplot.script_path)
    end

    for _, gnuplot in ipairs(graphs) do
        local file = io.open(gnuplot.data_path, "w")

        if not file then
            error(string.format('Path "%s" is not writable.', gnuplot.data_path), 0)
        end

        for _, artifact in ipairs(artifacts) do
            if vim.version.eq(_P.get_simple_version(artifact.versions.neovim), neovim_version) then
                file:write(string.format("%s %f\n", artifact.versions.release, gnuplot.data_getter(artifact)))
            end
        end

        file:close()
    end

    for _, gnuplot in ipairs(graphs) do
        local path = gnuplot.script_path
        local job = vim.fn.jobstart({ "gnuplot", path })
        local result = vim.fn.jobwait({ job })[1]

        if result ~= 0 then
            error(string.format('Could not make "%s" into a graph.', path), 0)
        end
    end
end

--- Create the `"benchmarks/all/artifacts/{VERSION_TAG-YYYY_MM_DD-HH_MM_SS}"` directory.
---
---@param release string
---    The current release to make. e.g. `"v1.2.3"`.
---@param profiler Profiler
---    The object used to record function call times.
---@param root string
---    The ".../benchmarks/all" directory to create or update.
---@param events _ProfileEvent[]
---    All of the profiler event data to consider. If no events are given, we
---    will use the global profiler's events instead.
---@return string
---    An absolute path to the created flamegraph.json file.
---@return string
---    An absolute path to the created profile.json file.
---@return string
---    An absolute path to the created timing.txt file.
---@return string
---    The contents of the timing.txt file.
---
function _P.write_graph_artifact(release, profiler, root, events)
    _LOGGER:info("Writing date-time profiler directory data.")
    local directory = vim.fs.joinpath(root, string.format("%s-%s", release, os.date("%Y_%m_%d-%H_%M_%S")))
    vim.fn.mkdir(directory, "p")

    local flamegraph_path = vim.fs.joinpath(directory, _FLAMEGRAPH_FILE_NAME)
    _P.write_flamegraph(profiler, flamegraph_path)

    local profile_path = vim.fs.joinpath(directory, _PROFILE_FILE_NAME)
    _P.write_profile_summary(release, profile_path, events)

    local timing_path = vim.fs.joinpath(directory, _TIMING_FILE_NAME)
    local timing_text = _P.write_timing(events, timing_path)

    return flamegraph_path, profile_path, timing_path, timing_text
end

--- Create the gnuplot line-graphs.
---
--- Raises:
---     If we cannot write the graphs (because of missing data, usually).
---
---@param artifacts _GraphArtifact[] All past profiling / timing records to make a graph.
---@param root string The ".../benchmarks/all" directory to create or update.
---@return _GnuplotData[] # The gnuplot data that was written to-disk.
---
function _P.write_graph_images(artifacts, root)
    local keep = os.getenv("BUSTED_PROFILER_KEEP_TEMPORARY_FILES") == "1"

    local mean_data_path
    local mean_image_path = vim.fs.joinpath(root, "mean.png")
    local mean_script_path
    local median_data_path
    local median_image_path = vim.fs.joinpath(root, "median.png")
    local median_script_path
    local std_data_path
    local std_image_path = vim.fs.joinpath(root, "standard_deviation.png")
    local std_script_path

    -- TODO: Make sure these images are in the README.md file

    if keep then
        mean_data_path = vim.fs.joinpath(root, "_mean.dat")
        mean_script_path = vim.fs.joinpath(root, "_mean.gnuplot")
        median_data_path = vim.fs.joinpath(root, "_median.dat")
        median_script_path = vim.fs.joinpath(root, "_media.gnuplot")
        std_data_path = vim.fs.joinpath(root, "_standard_deviation.dat")
        std_script_path = vim.fs.joinpath(root, "_standard_deviation.gnuplot")
    else
        mean_data_path = vim.fn.tempname() .. "_mean.dat"
        mean_script_path = vim.fn.tempname() .. "_mean.gnuplot"
        median_data_path = vim.fn.tempname() .. "_media.dat"
        median_script_path = vim.fn.tempname() .. "_media.gnuplot"
        std_data_path = vim.fn.tempname() .. "_standard_deviation.dat"
        std_script_path = vim.fn.tempname() .. "_standard_deviation.gnuplot"
    end

    ---@type _GnuplotData[]
    local graphs = {
        {
            data_getter = function(artifact)
                return artifact.statistics.mean
            end,
            data_path = mean_data_path,
            image_path = mean_image_path,
            script_data = string.format(_MEAN_SCRIPT_TEMPLATE, mean_image_path, mean_data_path),
            script_path = mean_script_path,
        },
        {
            data_getter = function(artifact)
                return artifact.statistics.median
            end,
            data_path = median_data_path,
            image_path = median_image_path,
            script_data = string.format(_MEDIAN_SCRIPT_TEMPLATE, median_image_path, median_data_path),
            script_path = median_script_path,
        },
        {
            data_getter = function(artifact)
                return artifact.statistics.standard_deviation
            end,
            data_path = std_data_path,
            image_path = std_image_path,
            script_data = string.format(_STD_SCRIPT_TEMPLATE, std_image_path, std_data_path),
            script_path = std_script_path,
        },
        -- TODO: Add a "all combined" graph here
    }

    local success, _ = pcall(_P.write_gnuplot_images, artifacts, graphs)

    if not keep then
        _LOGGER:fmt_debug('Deleting temporary files from "%s" graphs.', graphs)
        _P.delete_gnuplot_paths(graphs, { "data_path", "script_path" })
    end

    if not success then
        if not keep then
            _LOGGER:fmt_debug('Failed to write images. Deleting "%s" graphs.', graphs)
            _P.delete_gnuplot_paths(graphs, { "image_path" })
        end

        error("Failed to write all gnuplot graphs. Rolling back all files.", 0)
    end

    return graphs
end

--- Create a profile.json file to summarize the final results of the profiler.
---
--- Raises:
---     If `path` is not writable or fails to write.
---
---@param release string
---    The current release to make. e.g. `"v1.2.3"`.
---@param path string
---    An absolute path to the ".../benchmarks/all/profile.json" to create.
---@param events _ProfileEvent[]
---    All of the profiler event data to consider. If no events are given, we
---    will use the global profiler's events instead.
---
function _P.write_profile_summary(release, path, events)
    _LOGGER:fmt_info('Writing profile summary to "%s" path.', path)
    _P.make_parent_directory(path)

    local file = io.open(path, "w")

    if not file then
        error(string.format('Path "%s" could not be exported.', path), 0)
    end

    local cpu = _PROCESSOR

    ---@type _GraphArtifact
    local data = {
        versions = {
            lua = jit.version,
            neovim = vim.version(),
            release = release,
            uv = vim.uv.version(),
        },
        statistics = _P.get_profile_statistics(events),
        hardware = { cpu = cpu, platform = vim.loop.os_uname().sysname },
    }

    file:write(vim.json.encode(data))
    file:close()

    return data
end

--- Add graph data to the "benchmarks/all/README.md" file.
---
--- Or create the file if it does not exist.
---
--- Raises:
---     If `path` is not writeable.
---
---@param artifacts _GraphArtifact[] All found profile record events so far, if any.
---@param graphs _GnuplotData[] All of the graphs that were written to-disk.
---@param path string The path on-disk to write the README.md to.
---@param timing_text string The contents of the timing.txt file.
---
function _P.write_summary_readme(artifacts, graphs, path, timing_text)
    _P.make_parent_directory(path)

    local file = io.open(path, "w")

    if not file then
        error(string.format('Cannot append to "%s" path.', path), 0)
    end

    file:write([[
# Benchmarking Results

This document contains historical benchmarking results. These measure the speed
of resolution of a list of predetermined requests. Do **NOT** change this file
by hand; the Github workflows will do this automatically.

In the graph and data below, lower numbers are better

]])

    local directory = vim.fs.normalize(vim.fs.dirname(path))

    for _, graph in ipairs(graphs) do
        if vim.fs.normalize(vim.fs.dirname(graph.image_path)) ~= directory then
            error(
                string.format(
                    'Path "%s" is not relative to "%s". Cannot add it to the README.md',
                    graph.image_path,
                    directory
                ),
                0
            )
        end

        file:write(string.format('<p align="center"><img src="%s"/></p>\n', vim.fs.basename(graph.image_path)))
    end


    file:write(string.format("## Most Recent Timing\n\n```\n%s\n```\n\n", timing_text))

    file:write([[

## Past Runs

| Release | Platform | CPU | Neovim | Total | Median | Mean | StdDev |
|---------|----------|-----|--------|-------|--------|------|--------|
]])

    for _, artifact in ipairs(artifacts) do
        file:write(
            string.format(
                "| %s | %s | %s | %s | %s | %s | %s | %s |\n",
                artifact.versions.release,
                artifact.hardware.platform,
                artifact.hardware.cpu,
                _P.get_version_text(artifact.versions.neovim),
                artifact.statistics.total,
                artifact.statistics.median,
                artifact.statistics.mean,
                artifact.statistics.standard_deviation
            )
        )
    end
end

--- TODO: Docstring
---@param events _ProfileEvent[]
---@param path string
---@return string
function _P.write_timing(events, path)
    _LOGGER:fmt_info('Writing "%s" timing file.', path)
    local file = io.open(path, "w")

    if not file then
        error(string.format('Path "%s" could not be written.', path), 0)
    end

    local text = timing.get_profile_report_as_text(events, {thresold=_P.get_timing_threshold()})
    file:write(text)
    file:close()

    return text
end

--- Get all input data needed for us to run + save flamegraph data to-disk.
---
--- Raises:
---     If a required environment variable was not defined correctly.
---
---@return string # The absolute directory on-disk where flamegraph info will be written.
---@return string # The version to write to-disk. e.g. `"v1.2.3"`.
---
function M.get_environment_variable_data()
    local root = os.getenv("BUSTED_PROFILER_FLAMEGRAPH_OUTPUT_PATH")

    if not root then
        error("Cannot write profile results. $BUSTED_PROFILER_FLAMEGRAPH_OUTPUT_PATH is not defined.", 0)
    end

    local release = os.getenv("BUSTED_PROFILER_FLAMEGRAPH_VERSION")

    if not release then
        error("Cannot write profile results. $BUSTED_PROFILER_FLAMEGRAPH_VERSION is not defined.", 0)
    end

    _P.validate_release(release)

    return root, release
end

--- Add any missing information to `events`.
---
--- We mostly need this because profile.nvim doesn't add `pid` or `tid` to
--- events until the events are exported. And we need `tid` at least.
---
--- In the future hopefully this information is included by default and this
--- function can just be removed.
---
--- Warning:
---     `events` may be directly edited.
---
---@param events _ProfileEvent[]
---    All of the profiler event data to mutate.
---
function _P.extend_events(events)
    for _, event in ipairs(events) do
        -- TODO: Edit profile.nvim to export the default TID / PID
        event.pid = event.pid or 1
        event.tid = event.tid or 1
    end
end

--- Make sure `gnuplot` is installed and is accessible.
---
--- We can't generate a line-graph if we don't have access to this terminal command.
---
--- Raises:
---     If no `gnuplot` is found or is not callable.
---
function M.validate_gnuplot()
    local success, _ = pcall(vim.fn.system, { "gnuplot" })

    if not success then
        error("gnuplot does not exist or is not executable.", 0)
    end
end

--- Write all files for the "benchmarks/all" directory.
---
--- The basic directory structure looks like this:
---
--- - all/
---     - artifacts/
---         - {VERSION_TAG-YYYY_MM_DD-HH_MM_SS}/
---             - flamegraph.json
---             - profile.json
---     - README.md
---         - Show the graph of the output, across versions
---         - A table summary of the timing
---     - flamegraph.json
---     - profile.json - The latest release's total time, self time, etc
---     - *.png - Profiler-related line-graphs
---
--- Raises:
---    If an invalid `maximum` is given.
---
---@param release string
---    The current release to make. e.g. `"v1.2.3"`.
---@param profiler Profiler
---    The object used to record function call times.
---@param root string
---    The ".../benchmarks/all" directory to create or update.
---@param events _ProfileEvent[]?
---    All of the profiler event data to consider. If no events are given, we
---    will use the global profiler's events instead.
---@param maximum number?
---    A 1-or-more value. The number of samples to collect for graphing. If
---    there are more samples than `maximum` allows, the later smples are
---    preferred. Note: It is unwise to set this number higher than the default
---    (35). Experimentation showed that the X-axis of the graph becomes
---    unreadable after 35.
---
function M.write_all_summary_directory(release, profiler, root, events, maximum)
    _LOGGER:fmt_info('Now writing profiler "%s" results to "%s" path.', release, root)
    maximum = maximum or _DEFAULT_MAXIMUM_ARTIFACTS

    if maximum < 1 then
        error(string.format('Maximum "%s" must be >= 1.', maximum), 0)
    end

    local artifacts_root = vim.fs.joinpath(root, "artifacts")
    events = events or instrument.get_events()
    _P.extend_events(events)
    local flamegraph_path, profile_path, timing_path, timing_text = _P.write_graph_artifact(
        release,
        profiler,
        artifacts_root,
        events
    )
    local readme_path = vim.fs.joinpath(root, "README.md")

    local artifacts = _P.get_graph_artifacts(artifacts_root, maximum)

    if _P.is_stable_release(release) and _P.is_latest_version(_P.get_version_numbers(release), artifacts_root) then
        _LOGGER:fmt_info('Copying "%s" release to "%s" path.', release, root)
        _P.copy_file_to_directory(flamegraph_path, root)
        _P.copy_file_to_directory(profile_path, root)
        _P.copy_file_to_directory(timing_path, root)
    else
        _LOGGER:fmt_warning(
            'Release "%s" is not the latest, stable version. We skipped copying to the "%s" root directory.',
            release,
            root
        )
    end

    local graphs = _P.write_graph_images(artifacts, root)
    _P.write_summary_readme(artifacts, graphs, readme_path, timing_text)
end

return M
