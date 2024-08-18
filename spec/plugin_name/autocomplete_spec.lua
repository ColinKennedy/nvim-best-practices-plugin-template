-- TODO: Docstring
-- TODO: Move this to a standalone lua module

describe("default", function()
    it("works even if #empty #simple", function()
        assert.same({ {}, {} }, argparse.parse_args(""))
    end)
end)
