--- Make sure the Telescope integration works as expected.
---
---@module 'plugin_template.telescope_spec'
---

local mock_test = require("test_utilities.mock_test")
local plugin_template = require("telescope._extensions.plugin_template")
local runner = require("telescope._extensions.plugin_template.runner")
local telescope_actions = require("telescope.actions")
local telescope_actions_state = require("telescope.actions.state")

local _ORIGINAL_GET_SELECTION_FUNCTION = runner.get_selection
local _RESULT = nil

--- Tempoarily wrap `runner.get_selection` so we can use it for unittests.
local function _mock_get_selection()
    local function _mock(caller)
        ---@diagnostic disable-next-line: duplicate-set-field
        runner.get_selection = function(...)
            local selection = caller(...)
            _RESULT = selection

            return selection
        end
    end

    _mock(runner.get_selection)
end

--- Reset the unittests back to their original values.
local function _restore_get_selection()
    runner.get_selection = _ORIGINAL_GET_SELECTION_FUNCTION

    _RESULT = nil
end

--- Run Neovim's event loop so that all currently-scheduled function can run.
---
--- If you or some other API call `vim.schedule` / `vim.schedule_wrap` and want
--- to make sure that function runs, call this function.
---
---@param timeout number?
---    The milliseconds to wait before continuing. If the timeout is exceeded
---    then we stop waiting for all of the functions to call.
---
local function _wait_for_picker_to_initialize(timeout)
    if timeout == nil then
        timeout = 1000
    end

    local initialized = false

    vim.schedule(function()
        initialized = true
    end)

    vim.wait(timeout, function()
        return initialized
    end)
end

--- Wait for our (mocked) unittest variable to get some data back.
---
---@param timeout number?
---    The milliseconds to wait before continuing. If the timeout is exceeded
---    then we stop waiting for all of the functions to call.
---
local function _wait_for_result(timeout)
    if timeout == nil then
        timeout = 1000
    end

    vim.wait(timeout, function()
        return _RESULT ~= nil
    end)
end

--- Create a Telescope picker for `command` and get the created "prompt" buffer back.
---
---@param command string
---    A Telescope sub-command. e.g. If the command was `:Telescope
---    plugin_template foo` then this function would require `"foo"`.
---
local function _make_telescope_picker(command)
    plugin_template.exports[command]()

    _wait_for_picker_to_initialize()

    return vim.api.nvim_get_current_buf()
end

--- Setup all mocks and get ready for the unittest to run.
local function _initialize_all()
    _mock_get_selection()
    mock_test.silence_all_internal_prints()
end

describe("telescope goodnight-moon", function()
    before_each(_initialize_all)
    after_each(_restore_get_selection)

    it("selects a book", function()
        local buffer = _make_telescope_picker("goodnight-moon")
        telescope_actions.select_default(buffer)
        _wait_for_result()

        assert.same({ "Buzz Bee - Cool Person" }, _RESULT)
    end)

    it("selects 2+ books", function()
        local buffer = _make_telescope_picker("goodnight-moon")
        local picker = telescope_actions_state.get_current_picker(buffer)
        picker:set_selection(picker.max_results - picker.manager:num_results())
        telescope_actions.move_selection_previous(buffer)
        picker:toggle_selection(picker:get_selection_row())
        telescope_actions.move_selection_previous(buffer)
        picker:toggle_selection(picker:get_selection_row())
        telescope_actions.select_default(buffer)
        _wait_for_result()

        assert.same({
            "Buzz Bee - Cool Person",
            "Fizz Drink - Some Name",
        }, _RESULT)
    end)
end)

describe("telescope hello-world", function()
    before_each(_initialize_all)
    after_each(_restore_get_selection)

    it("selects a phrase", function()
        local buffer = _make_telescope_picker("hello-world")
        telescope_actions.select_default(buffer)
        _wait_for_result()

        assert.same({ "What's up, doc?" }, _RESULT)
    end)

    it("selects 2+ phrases", function()
        local buffer = _make_telescope_picker("hello-world")
        local picker = telescope_actions_state.get_current_picker(buffer)
        picker:set_selection(picker.max_results - picker.manager:num_results())
        telescope_actions.move_selection_previous(buffer)
        picker:toggle_selection(picker:get_selection_row())
        telescope_actions.move_selection_previous(buffer)
        picker:toggle_selection(picker:get_selection_row())
        telescope_actions.select_default(buffer)
        _wait_for_result()

        assert.same({ "What's up, doc?", "Hello, Sailor!" }, _RESULT)
    end)
end)
