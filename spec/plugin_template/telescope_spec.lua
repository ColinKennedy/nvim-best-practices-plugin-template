--- Make sure the Telescope integration works as expected.
---
--- @module 'plugin_template.telescope_spec'
---

-- TODO: Docstrings

local mock_test = require("test_utilities.mock_test")
local plugin_template = require("telescope._extensions.plugin_template")
local runner = require("telescope._extensions.plugin_template.runner")
local telescope_actions = require("telescope.actions")
local telescope_actions_state = require("telescope.actions.state")


--- @diagnostic disable: undefined-field

local _ORIGINAL_GET_SELECTION_FUNCTION = runner.get_selection
local _RESULT = nil


local function _mock_get_selection()
    local function _mock(caller)
        runner.get_selection = function(...)
            local selection = caller(...)
            _RESULT = selection

            return selection
        end
    end

    return _mock(runner.get_selection)
end


local function _restore_get_selection()
    runner.get_selection = _ORIGINAL_GET_SELECTION_FUNCTION

    _RESULT = nil
end


local function _wait_for_picker_to_initialize(timeout)
    if timeout == nil then
        timeout = 1000
    end

    local initialized = false

    vim.schedule(function() initialized = true end)

    vim.wait(timeout, function() return initialized end)
end


local function _wait_for_result(timeout)
    if timeout == nil then
        timeout = 1000
    end

    vim.wait(timeout, function() return _RESULT ~= nil end)
end


local function _make_telescope_picker(command)
    plugin_template.exports[command]()

    _wait_for_picker_to_initialize()

    return vim.api.nvim_get_current_buf()
end


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

        assert.same(
            {"Guns, Germs, and Steel: The Fates of Human Societies - Jared M. Diamond"},
            _RESULT
        )
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

        assert.same(
            {
                "Guns, Germs, and Steel: The Fates of Human Societies - Jared M. Diamond",
                "Herodotus Histories - Herodotus",
            },
            _RESULT
        )
    end)
end)

describe("telescope hello-world", function()
    before_each(_initialize_all)
    after_each(_restore_get_selection)

    it("selects a phrase", function()
        local buffer = _make_telescope_picker("hello-world")
        telescope_actions.select_default(buffer)
        _wait_for_result()

        assert.same(
            {"Hi there!"},
            _RESULT
        )
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

        assert.same( { "Hi there!", "Hello, Sailor!", }, _RESULT)
    end)
end)
